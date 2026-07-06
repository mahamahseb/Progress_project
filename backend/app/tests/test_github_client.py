from app.modules.github.client import GitHubClient


class FakeResponse:
    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, *args: object) -> None:
        return None

    def read(self) -> bytes:
        return b"# Project: Demo\n"


def test_fetch_file_uses_raw_github_url(monkeypatch) -> None:
    captured = {}

    def fake_urlopen(request, timeout):
        captured["url"] = request.full_url
        captured["timeout"] = timeout
        return FakeResponse()

    monkeypatch.setattr("app.modules.github.client.urlopen", fake_urlopen)

    content = GitHubClient(token="secret").fetch_file(
        repo="owner/repo",
        branch="main",
        path="docs/prd.md",
    )

    assert content == "# Project: Demo\n"
    assert captured["url"] == "https://raw.githubusercontent.com/owner/repo/main/docs/prd.md"
    assert captured["timeout"] == 15
