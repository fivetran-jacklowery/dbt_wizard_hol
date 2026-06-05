#!/usr/bin/env python3
"""Load the HOL retail demo data into Databricks Unity Catalog.

This loader keeps the canonical row data in ``dml.sql`` and executes the
Databricks-compatible ``ddl.sql``/``dml.sql`` through the lab dbt profile. It
intentionally targets ``hol_dbx_catalog`` by default so the lab has one Unity
Catalog home base.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable

import yaml


DEFAULT_CATALOG = "hol_dbx_catalog"
DEFAULT_SCHEMA = "hol_2026_retail"
DEFAULT_PROFILE = "hol_dbx_profile"


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(
        description="Create and populate the HOL retail raw schema in Databricks."
    )
    parser.add_argument("--profile", default=DEFAULT_PROFILE)
    parser.add_argument("--target", default=None)
    parser.add_argument("--catalog", default=DEFAULT_CATALOG)
    parser.add_argument("--schema", default=DEFAULT_SCHEMA)
    parser.add_argument("--profiles-yml", default=str(Path.home() / ".dbt" / "profiles.yml"))
    parser.add_argument("--ddl", default=str(script_dir / "ddl.sql"))
    parser.add_argument("--dml", default=str(script_dir / "dml.sql"))
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Write converted SQL files next to the source scripts without executing.",
    )
    return parser.parse_args()


def quote_identifier(identifier: str) -> str:
    return f"`{identifier.replace('`', '``')}`"


def qualified_schema(catalog: str, schema: str) -> str:
    return f"{quote_identifier(catalog)}.{quote_identifier(schema)}"


def convert_type(type_sql: str) -> str:
    type_sql = re.sub(r"VARCHAR\(\d+\)", "STRING", type_sql, flags=re.IGNORECASE)
    type_sql = re.sub(r"TIMESTAMP_NTZ\(\d+\)", "TIMESTAMP", type_sql, flags=re.IGNORECASE)
    type_sql = re.sub(r"TIMESTAMP_TZ\(\d+\)", "TIMESTAMP", type_sql, flags=re.IGNORECASE)

    def replace_number(match: re.Match[str]) -> str:
        precision = int(match.group(1))
        scale = int(match.group(2))
        if scale == 0:
            return "BIGINT"
        return f"DECIMAL({precision},{scale})"

    return re.sub(r"NUMBER\((\d+),\s*(\d+)\)", replace_number, type_sql, flags=re.IGNORECASE)


def strip_table_constraints(sql: str) -> str:
    output: list[str] = []
    for line in sql.splitlines():
        stripped = line.strip()
        if stripped.startswith("PRIMARY KEY"):
            continue
        if stripped.startswith("CONSTRAINT ") and " UNIQUE " in f" {stripped} ":
            continue
        output.append(line)

    sql = "\n".join(output)
    return re.sub(r",\n(\s*\);)", r"\n\1", sql)


def remove_alter_constraints(sql: str) -> str:
    return re.sub(
        r"^\s*ALTER TABLE\s+.*?;\s*",
        "\n",
        sql,
        flags=re.IGNORECASE | re.DOTALL | re.MULTILINE,
    )


def remove_sql_comments(sql: str) -> str:
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    return re.sub(r"^\s*--.*$", "", sql, flags=re.MULTILINE)


def convert_ddl(source_sql: str, catalog: str, schema: str) -> str:
    sql = re.sub(r"CREATE CATALOG IF NOT EXISTS\s+`?[^`;\s]+`?;", f"CREATE CATALOG IF NOT EXISTS {quote_identifier(catalog)};", source_sql, flags=re.IGNORECASE)
    sql = re.sub(r"CREATE SCHEMA IF NOT EXISTS\s+`?[^`.\s]+`?\.`?[^`;\s]+`?;", f"CREATE SCHEMA IF NOT EXISTS {qualified_schema(catalog, schema)};", sql, flags=re.IGNORECASE)
    sql = re.sub(r"USE CATALOG\s+`?[^`;\s]+`?;", f"USE CATALOG {quote_identifier(catalog)};", sql, flags=re.IGNORECASE)
    sql = re.sub(r"USE SCHEMA\s+`?[^`;\s]+`?;", f"USE SCHEMA {quote_identifier(schema)};", sql, flags=re.IGNORECASE)
    sql = convert_type(sql)
    sql = strip_table_constraints(sql)
    return remove_alter_constraints(sql)


def convert_dml(source_sql: str, catalog: str, schema: str) -> str:
    sql = re.sub(r"USE CATALOG\s+`?[^`;\s]+`?;", f"USE CATALOG {quote_identifier(catalog)};", source_sql, flags=re.IGNORECASE)
    return re.sub(r"USE SCHEMA\s+`?[^`;\s]+`?;", f"USE SCHEMA {quote_identifier(schema)};", sql, flags=re.IGNORECASE)


def split_sql(sql: str) -> Iterable[str]:
    statement: list[str] = []
    in_single_quote = False
    in_line_comment = False
    in_block_comment = False
    index = 0

    while index < len(sql):
        char = sql[index]
        next_char = sql[index + 1] if index + 1 < len(sql) else ""

        if in_line_comment:
            statement.append(char)
            if char == "\n":
                in_line_comment = False
            index += 1
            continue

        if in_block_comment:
            statement.append(char)
            if char == "*" and next_char == "/":
                statement.append(next_char)
                in_block_comment = False
                index += 2
            else:
                index += 1
            continue

        if in_single_quote:
            statement.append(char)
            if char == "'" and next_char == "'":
                statement.append(next_char)
                index += 2
                continue
            if char == "'":
                in_single_quote = False
            index += 1
            continue

        if char == "-" and next_char == "-":
            statement.extend([char, next_char])
            in_line_comment = True
            index += 2
            continue

        if char == "/" and next_char == "*":
            statement.extend([char, next_char])
            in_block_comment = True
            index += 2
            continue

        if char == "'":
            statement.append(char)
            in_single_quote = True
            index += 1
            continue

        if char == ";":
            text = "".join(statement).strip()
            if text and remove_sql_comments(text).strip():
                yield text
            statement = []
            index += 1
            continue

        statement.append(char)
        index += 1

    text = "".join(statement).strip()
    if text and remove_sql_comments(text).strip():
        yield text


def load_profile(path: Path, profile_name: str, target_name: str | None) -> dict[str, str]:
    profiles = yaml.safe_load(path.read_text())
    profile = profiles[profile_name]
    target = target_name or profile["target"]
    output = profile["outputs"][target]
    return {
        "host": output["host"],
        "http_path": output["http_path"],
        "client_id": output["client_id"],
        "client_secret": output["client_secret"],
    }


def execute_sql(statements: Iterable[str], profile: dict[str, str]) -> None:
    from databricks import sql
    from databricks.sdk.core import Config, oauth_service_principal

    config = Config(
        host=f"https://{profile['host']}",
        client_id=profile["client_id"],
        client_secret=profile["client_secret"],
    )
    credentials_provider = oauth_service_principal(config)

    with sql.connect(
        server_hostname=profile["host"],
        http_path=profile["http_path"],
        credentials_provider=lambda: credentials_provider,
    ) as connection:
        with connection.cursor() as cursor:
            for number, statement in enumerate(statements, start=1):
                first_line = statement.splitlines()[0][:100]
                print(f"[{number:03d}] {first_line}")
                cursor.execute(statement)


def main() -> None:
    args = parse_args()
    ddl_path = Path(args.ddl)
    dml_path = Path(args.dml)
    converted_ddl = convert_ddl(ddl_path.read_text(), args.catalog, args.schema)
    converted_dml = convert_dml(dml_path.read_text(), args.catalog, args.schema)

    ddl_out = ddl_path.with_name("ddl_databricks.generated.sql")
    dml_out = dml_path.with_name("dml_databricks.generated.sql")
    ddl_out.write_text(converted_ddl)
    dml_out.write_text(converted_dml)
    print(f"Wrote {ddl_out}")
    print(f"Wrote {dml_out}")

    if args.dry_run:
        return

    profile = load_profile(Path(args.profiles_yml), args.profile, args.target)
    statements = [*split_sql(converted_ddl), *split_sql(converted_dml)]
    execute_sql(statements, profile)
    print(f"Loaded HOL data into {args.catalog}.{args.schema}")


if __name__ == "__main__":
    main()
