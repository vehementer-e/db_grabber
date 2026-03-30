def test_jgen_procedure():
    """
    Smoke test for procedure jgen.
    """

    schema = "collection"
    proc = "reportCollectionNonPaymentReason"

    from docsgen.db import get_connection
    from docsgen.jgen.procedure import get_procedure_metadata

    with get_connection() as conn:
        doc = get_procedure_metadata(conn, schema, proc)

    assert doc is not None, "Returned value is None"
    assert isinstance(doc, dict), "Returned value is not dict"
    assert len(doc) > 0, "Returned dict is empty"

    assert doc.get("object_type") == "procedure"
    assert doc.get("schema") == schema
    assert doc.get("name") == proc


def test_jgen_function_returns_non_empty_json():
    """
    Smoke test for function jgen.
    """
    schema = "dbo"
    func = "tvf_getBranchByCode"

    from docsgen.db import get_connection
    from docsgen.jgen.function import get_function_metadata

    with get_connection() as conn:
        doc = get_function_metadata(conn, schema, func)

    assert doc is not None
    assert isinstance(doc, dict)
    assert len(doc) > 0

    assert doc.get("object_type") == "function"
    assert doc.get("schema") == schema
    assert doc.get("name") == func


def test_jgen_table_returns_non_empty_json():
    """
    Smoke test for table jgen.
    """
    # CollectionNonPaymentReasonFullDetail
    schema = "collection"
    table = "CollectionNonPaymentReasonFullDetail"

    from docsgen.db import get_connection
    from docsgen.jgen.table import get_table_metadata

    with get_connection() as conn:
        doc = get_table_metadata(conn, schema, table)

    assert doc is not None
    assert isinstance(doc, dict)
    assert len(doc) > 0

    assert doc.get("object_type") == "table"
    assert doc.get("schema") == schema
    assert doc.get("name") == table

    assert "columns" in doc
    assert isinstance(doc["columns"], list)
    assert len(doc["columns"]) > 0