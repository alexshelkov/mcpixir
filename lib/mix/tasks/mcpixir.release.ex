defmodule Mix.Tasks.Mcpixir.Release do
  @moduledoc """
  Handles the release process for Mcpixir.

  This task automates the release process, including:
  - Verifying the project is in a clean state
  - Updating version numbers
  - Updating the CHANGELOG
  - Creating a git tag
  - Publishing to Hex.pm

  ## Usage

      mix mcpixir.release VERSION

  Where VERSION is the new version number in the format MAJOR.MINOR.PATCH.

  ## Examples

      mix mcpixir.release 0.2.0
      mix mcpixir.release 1.0.0

  """
  use Mix.Task

  alias Mcpixir

  @shortdoc "Releases a new version of Mcpixir"

  @impl Mix.Task
  def run(args) do
    [version] = validate_args!(args)

    # Check if git is clean
    check_git_clean!()

    # Update version in mix.exs
    update_version!(version)

    # Update CHANGELOG.md
    update_changelog!(version)

    # Run tests
    run_tests!()

    # Compile documentation
    compile_docs!()

    # Git commit and tag
    commit_and_tag!(version)

    # Publish to Hex.pm
    publish_to_hex!()

    IO.puts(IO.ANSI.green() <> "Release v#{version} completed successfully!" <> IO.ANSI.reset())
    IO.puts("Don't forget to push the changes and tag:")
    IO.puts("  git push --follow-tags")
  end

  defp validate_args!(args) do
    case args do
      [version] ->
        if Regex.match?(~r/^\d+\.\d+\.\d+$/, version) do
          [version]
        else
          raise "Version must be in the format MAJOR.MINOR.PATCH"
        end

      _ ->
        raise "Expected a single argument: VERSION"
    end
  end

  defp check_git_clean! do
    case System.cmd("git", ["status", "--porcelain"]) do
      {"", 0} ->
        :ok

      {output, 0} ->
        raise """
        Git working directory is not clean. Please commit or stash your changes before releasing.

        #{output}
        """

      {_, _} ->
        raise "Failed to check git status"
    end
  end

  defp update_version!(version) do
    IO.puts("Updating version to #{version}...")

    # Read the current mix.exs
    mix_file = File.read!("mix.exs")

    # Replace version number
    updated_mix = Regex.replace(~r/@version \"[\d\.]+\"/, mix_file, "@version \"#{version}\"")

    # Write back to mix.exs
    File.write!("mix.exs", updated_mix)
  end

  defp update_changelog!(version) do
    IO.puts("Updating CHANGELOG.md...")

    # Get the current date
    date = Date.utc_today() |> Date.to_string()

    # Read the current CHANGELOG.md
    changelog = File.read!("CHANGELOG.md")

    # Replace the Unreleased section with the new version
    updated_changelog =
      Regex.replace(
        ~r/## \[Unreleased\]\n\n/,
        changelog,
        """
        ## [Unreleased]

        ## [#{version}] - #{date}

        """
      )

    # Write back to CHANGELOG.md
    File.write!("CHANGELOG.md", updated_changelog)
  end

  defp run_tests! do
    IO.puts("Running tests...")

    cmd_output = System.cmd("mix", ["test"], stderr_to_stdout: true)
    case cmd_output do
      {_, 0} -> :ok
      {output, _} -> raise "Tests failed, aborting release\n#{output}"
    end
  end

  defp compile_docs! do
    IO.puts("Compiling documentation...")

    cmd_output = System.cmd("mix", ["docs"], stderr_to_stdout: true)
    case cmd_output do
      {_, 0} -> :ok
      {output, _} -> raise "Documentation compilation failed, aborting release\n#{output}"
    end
  end

  defp commit_and_tag!(version) do
    IO.puts("Creating git commit and tag...")

    # Commit changes
    System.cmd("git", ["add", "mix.exs", "CHANGELOG.md"])
    System.cmd("git", ["commit", "-m", "Release v#{version}"])

    # Create tag
    System.cmd("git", ["tag", "-a", "v#{version}", "-m", "Release v#{version}"])
  end

  defp publish_to_hex! do
    IO.puts("Publishing to Hex.pm...")

    cmd_output = System.cmd("mix", ["hex.publish"], stderr_to_stdout: true)
    case cmd_output do
      {_, 0} -> :ok
      {output, _} -> raise "Failed to publish to Hex.pm\n#{output}"
    end
  end
end
