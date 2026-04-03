{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = [ pkgs.git pkgs.jq ];

  # https://devenv.sh/supported-languages/javascript/
  languages.javascript.enable = true;
  languages.javascript.npm.enable = true;

  enterShell = ''
    npx -y skills add -y https://mintlify.com/docs 2>/dev/null
  '';

  scripts.aggregate-docs = {
    description = "Clone subrepo docs and merge navigation into docs.json";
    exec = ''
      set -euo pipefail

      REPO_ROOT="''${DEVENV_ROOT:-.}"

      # --- Repository definitions: name=docs-subdir ---
      declare -A REPOS=(
        ["Marchyo"]="docs"
        ["Jotain"]="docs"
        ["jstack"]="docs"
      )

      REPO_NAMES=()
      for repo in "''${!REPOS[@]}"; do
        subdir="''${REPOS[$repo]}"
        target="$(echo "$repo" | tr '[:upper:]' '[:lower:]')"
        echo "::group::Clone jylhis/$repo"

        rm -rf "$REPO_ROOT/$target"
        rm -rf "$REPO_ROOT/_clone_$repo"

        git clone --depth=1 "https://github.com/jylhis/''${repo}.git" "$REPO_ROOT/_clone_$repo"

        if [ -d "$REPO_ROOT/_clone_$repo/$subdir" ]; then
          mv "$REPO_ROOT/_clone_$repo/$subdir" "$REPO_ROOT/$target"
        else
          echo "Warning: $repo has no $subdir directory, skipping"
          rm -rf "$REPO_ROOT/_clone_$repo"
          continue
        fi

        rm -rf "$REPO_ROOT/_clone_$repo"
        REPO_NAMES+=("$target")
        echo "::endgroup::"
      done

      # --- Merge navigation from each subrepo into main docs.json ---
      node -e '
        const fs = require("fs");
        const path = require("path");

        const repos = JSON.parse(process.argv[1]);
        const mainConfig = JSON.parse(fs.readFileSync("docs.json", "utf-8"));

        function prependPrefix(group, prefix) {
          return {
            ...group,
            pages: group.pages.map(entry =>
              typeof entry === "string"
                ? prefix + "/" + entry
                : prependPrefix(entry, prefix)
            ),
          };
        }

        for (const repo of repos) {
          let subConfig;
          const docsPath = path.join(repo, "docs.json");
          const mintPath = path.join(repo, "mint.json");

          if (fs.existsSync(docsPath)) {
            subConfig = JSON.parse(fs.readFileSync(docsPath, "utf-8"));
            fs.unlinkSync(docsPath);
          } else if (fs.existsSync(mintPath)) {
            subConfig = JSON.parse(fs.readFileSync(mintPath, "utf-8"));
            fs.unlinkSync(mintPath);
          } else {
            continue;
          }

          const nav = subConfig.navigation;
          const allGroups = [];

          if (Array.isArray(nav)) {
            // mint.json: flat array of groups
            for (const g of nav) {
              allGroups.push(prependPrefix(g, repo));
            }
          } else if (nav && nav.tabs) {
            // docs.json: tabs containing groups as page entries
            for (const tab of nav.tabs) {
              if (tab.pages) {
                for (const entry of tab.pages) {
                  if (typeof entry === "string") {
                    allGroups.push({ group: tab.tab, pages: [repo + "/" + entry] });
                  } else if (entry.group && entry.pages) {
                    allGroups.push(prependPrefix(entry, repo));
                  }
                }
              }
              if (tab.groups) {
                for (const g of tab.groups) {
                  allGroups.push(prependPrefix(g, repo));
                }
              }
            }
          } else if (nav && nav.groups) {
            // docs.json with flat groups
            for (const g of nav.groups) {
              allGroups.push(prependPrefix(g, repo));
            }
          }

          if (allGroups.length > 0) {
            mainConfig.navigation.tabs.push({
              tab: repo,
              groups: allGroups,
            });
          }
        }

        fs.writeFileSync("docs.json", JSON.stringify(mainConfig, null, 2));
      ' "$(printf '%s\n' "''${REPO_NAMES[@]}" | jq -R . | jq -s .)"

      # --- Clean up subrepo-specific configs that conflict with main site ---
      for repo in "''${REPO_NAMES[@]}"; do
        rm -f "$REPO_ROOT/$repo/mint.json" \
              "$REPO_ROOT/$repo/favicon.svg" \
              "$REPO_ROOT/$repo/.mintignore"
        rm -rf "$REPO_ROOT/$repo/logo"
      done

      echo "Aggregation complete."
    '';
  };

  # https://devenv.sh/integrations/claude-code/
  claude.code.enable = true;

  claude.code.mcpServers = {
    devenv = {
      type = "stdio";
      command = "devenv";
      args = [ "mcp" ];
      env = { DEVENV_ROOT = config.devenv.root; };
    };
    Mintlify = {
      type = "http";
      url = "https://mintlify.com/docs/mcp";
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
