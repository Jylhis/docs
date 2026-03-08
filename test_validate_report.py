import os
import json
import pytest
from validate_report import validate_json_report

def test_validate_json_report_valid(tmp_path, capsys):
    d = tmp_path / "reports"
    d.mkdir()
    p = d / "valid.json"
    data = {"status": "success", "data": [1, 2, 3]}
    p.write_text(json.dumps(data))

    # Function prints to stdout on error, should print nothing on success
    # Using capsys to verify no error message is printed
    validate_json_report(str(p))
    captured = capsys.readouterr()
    assert captured.out == ""
    assert captured.err == ""

def test_validate_json_report_invalid(tmp_path, capsys):
    d = tmp_path / "reports"
    d.mkdir()
    p = d / "invalid.json"
    p.write_text("{ 'invalid': json }") # malformed json

    validate_json_report(str(p))
    captured = capsys.readouterr()
    assert "Error loading JSON" in captured.err

def test_validate_json_report_nonexistent(capsys):
    validate_json_report("nonexistent_file.json")
    captured = capsys.readouterr()
    assert "Error loading JSON" in captured.err
    assert "No such file or directory" in captured.err
