import typer
import subprocess

app = typer.Typer(help="Developer CLI for nbdev blockchain project")

@app.command()
def docs():
    """📄 Build and preview documentation using Quarto via nbdev"""
    typer.echo("⏳ Building and launching docs...")
    subprocess.run(["poetry", "run", "nbdev_docs"], check=True)

@app.command()
def test(preview: bool = typer.Option(False, help="Also run nbdev_preview in background")):
    """✅ Run all tests with pytest and optionally preview docs"""
    typer.echo("🧪 Running nbdev_prepare...")
    subprocess.run(["poetry", "run", "nbdev_prepare"], check=True)

    if preview:
        typer.echo("🌐 Launching nbdev preview (in background)...")
        subprocess.Popen(["poetry", "run", "nbdev_preview"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        typer.echo("🚀 Preview available at http://localhost:3771")

@app.command()
def stop_preview():
    """❌ Stop the running nbdev_preview server (Windows only)"""
    typer.echo("🔻 Killing nbdev_preview process (quarto.exe)...")
    subprocess.run(["taskkill", "/F", "/IM", "quarto.exe"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

@app.command()
def build():
    """📦 Build the Python package using poetry"""
    typer.echo("📦 Building project with poetry...")
    subprocess.run(["poetry", "build"], check=True)

if __name__ == "__main__":
    app()
