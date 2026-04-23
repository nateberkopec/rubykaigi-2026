#!/usr/bin/env fish

function show_help
    echo "Deckset PDF exporter"
    echo
    echo "Usage: build-pdf.fish [OPTIONS]"
    echo
    echo "Options:"
    echo "  -o, --output PATH   Output PDF path (default: dist/(repo name).pdf)"
    echo "      --notes         Include presenter notes in the export"
    echo "  -h, --help          Show help"
    echo
    echo "Examples:"
    echo "  mise run build"
    echo "  mise run build -- --notes"
    echo "  mise run build -- --output dist/handout.pdf"
end

function info_msg
    if command -sq gum
        gum style --foreground 212 --bold "$argv"
    else
        echo "$argv"
    end
end

function error_msg
    if command -sq gum
        gum style --foreground 196 --bold "$argv" >&2
    else
        echo "$argv" >&2
    end
end

set script_dir (cd (dirname (status --current-filename)); pwd)
set repo_root (cd "$script_dir/.."; pwd)
set deck_path "$repo_root/DECKSET.md"
set repo_name (basename "$repo_root")
set output_path "dist/$repo_name.pdf"
set include_notes false
set expect_output_path false

for arg in $argv
    if test "$expect_output_path" = true
        set output_path "$arg"
        set expect_output_path false
        continue
    end

    switch $arg
        case -h --help
            show_help
            exit 0
        case --notes
            set include_notes true
        case -o --output
            set expect_output_path true
        case '*'
            error_msg "Unexpected argument: $arg"
            echo >&2
            show_help >&2
            exit 1
    end
end

if test "$expect_output_path" = true
    error_msg "Missing path after --output"
    exit 1
end

if not test -f "$deck_path"
    error_msg "Could not find $deck_path"
    exit 1
end

if not test -d /Applications/Deckset.app
    error_msg "Deckset.app not found in /Applications"
    exit 1
end

if not string match -rq '^/' -- "$output_path"
    set output_path "$repo_root/$output_path"
end

set output_dir (dirname "$output_path")
mkdir -p "$output_dir"

info_msg "Exporting Deckset presentation"
echo "Input:  $deck_path"
echo "Output: $output_path"
echo "Notes:  $include_notes"

begin
    echo 'on run argv'
    echo '    set deckPathText to (item 1 of argv)'
    echo '    set outputPathText to (item 2 of argv)'
    echo '    set includeNotesText to (item 3 of argv)'
    echo '    set includeNotesValue to includeNotesText is "true"'
    echo '    set deckFile to POSIX file deckPathText'
    echo '    set outputFile to POSIX file outputPathText'
    echo '    set targetDocument to missing value'
    echo ''
    echo '    tell application "Deckset"'
    echo '        open deckFile'
    echo ''
    echo '        repeat 100 times'
    echo '            try'
    echo '                repeat with aDocument in documents'
    echo '                    if POSIX path of (file of aDocument as alias) is deckPathText then'
    echo '                        set targetDocument to aDocument'
    echo '                        exit repeat'
    echo '                    end if'
    echo '                end repeat'
    echo '            end try'
    echo ''
    echo '            if targetDocument is not missing value then'
    echo '                exit repeat'
    echo '            end if'
    echo ''
    echo '            delay 0.1'
    echo '        end repeat'
    echo ''
    echo '        if targetDocument is missing value then'
    echo '            error "Deckset did not open the presentation."'
    echo '        end if'
    echo ''
    echo '        export targetDocument to outputFile as "PDF" printAllSteps false includePresenterNotes includeNotesValue'
    echo '    end tell'
    echo 'end run'
end | osascript - "$deck_path" "$output_path" "$include_notes"
set export_status $status

if test $export_status -ne 0
    error_msg "Deckset export failed"
    exit $export_status
end

if not test -f "$output_path"
    error_msg "Deckset finished without producing $output_path"
    exit 1
end

info_msg "PDF written"
ls -lh "$output_path"
