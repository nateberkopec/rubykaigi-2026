#!/usr/bin/env fish

function show_help
    echo "Deckset timer"
    echo
    echo "Usage: pecha-kucha.fish [OPTIONS] [VALUE]"
    echo
    echo "Timing modes:"
    echo "  --interval     VALUE is seconds per slide"
    echo "  --total-time   VALUE is total presentation time"
    echo
    echo "Run modes:"
    echo "  --present      Start in presentation mode (default for mise present)"
    echo "  --rehearse     Start in rehearsal mode (default for mise rehearse)"
    echo
    echo "Recovery modes:"
    echo "  --pick         Pick a starting slide by slide text"
    echo "  --resume       Resume from the last saved checkpoint"
    echo
    echo "Other options:"
    echo "  --no-skip-title  Do not skip the title slide (default)"
    echo "  --skip-title     Skip the title slide when starting from slide 1"
    echo "  --dry-run        Print computed timing, do not open Deckset"
    echo "  -h, --help       Show help"
    echo
    echo "Defaults:"
    echo "  present:  25 minutes total time"
    echo "  rehearse: 25 minutes total time"
    echo
    echo "VALUE formats:"
    echo "  interval mode:    15, 15s, 0.5m"
    echo "  total-time mode:  25, 25m, 1500s, 25:00"
    echo "                     plain numbers in total-time mode mean minutes"
    echo
    echo "Examples:"
    echo "  mise run present"
    echo "  mise run present -- 25"
    echo "  mise run present -- --pick"
    echo "  mise run present -- --resume"
    echo "  mise run rehearse -- 25m"
    echo "  mise run rehearse -- --pick 20"
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

function parse_duration_seconds -a raw default_unit
    set raw (string trim -- "$raw")

    if string match -rq '^[0-9]+([.][0-9]+)?$' -- "$raw"
        switch $default_unit
            case minutes
                math "$raw * 60"
            case seconds
                echo "$raw"
        end
        return 0
    end

    if string match -rq '^[0-9]+([.][0-9]+)?s$' -- "$raw"
        string replace -r 's$' '' -- "$raw"
        return 0
    end

    if string match -rq '^[0-9]+([.][0-9]+)?m$' -- "$raw"
        set minutes (string replace -r 'm$' '' -- "$raw")
        math "$minutes * 60"
        return 0
    end

    if string match -rq '^[0-9]+:[0-9]{2}$' -- "$raw"
        set parts (string split ':' -- "$raw")
        set minutes $parts[1]
        set seconds $parts[2]
        math "$minutes * 60 + $seconds"
        return 0
    end

    return 1
end

function slide_catalog -a deck_path
    begin
        echo 'import re, sys'
        echo 'from pathlib import Path'
        echo 'text = Path(sys.argv[1]).read_text()'
        echo 'slides = [s.strip() for s in re.split(r"(?m)^\\s*---\\s*$", text) if s.strip()]'
        echo 'metadata = re.compile(r"^[a-z0-9_-]+:\\s*.+$", re.I)'
        echo 'if slides:'
        echo '    first_lines = [line.strip() for line in slides[0].splitlines() if line.strip()]'
        echo '    if first_lines and all(metadata.match(line) for line in first_lines):'
        echo '        slides = slides[1:]'
        echo 'control = re.compile(r"^\\[(?:ticks?:\\s*\\d+(?:x)?|slide-skin:\\s*[a-z0-9_-]+)\\]\\s*$", re.I)'
        echo 'directive = re.compile(r"^\\[[^\\]]+\\]\\s*$")'
        echo 'def label_for(slide, idx):'
        echo '    lines = [line.strip() for line in slide.splitlines() if line.strip()]'
        echo '    while lines and control.match(lines[0]):'
        echo '        lines.pop(0)'
        echo '    heading = ""'
        echo '    first_content = ""'
        echo '    first_text = ""'
        echo '    for line in lines:'
        echo '        if control.match(line) or directive.match(line) or metadata.match(line):'
        echo '            continue'
        echo '        if not first_content:'
        echo '            first_content = line'
        echo '        if not first_text and not line.startswith("!["):'
        echo '            first_text = line'
        echo '        if re.match(r"^#{1,6}\\s+", line):'
        echo '            heading = line'
        echo '            break'
        echo '    candidate = heading or first_text or first_content'
        echo '    if not candidate:'
        echo '        candidate = f"Slide {idx}"'
        echo '    candidate = re.sub(r"^#{1,6}\\s*", "", candidate)'
        echo '    candidate = re.sub(r"^\\^\\s*", "", candidate)'
        echo '    candidate = re.sub(r"!\\[[^\\]]*\\]\\([^)]+\\)", "[image]", candidate)'
        echo '    candidate = re.sub(r"\\[([^\\]]+)\\]\\([^)]+\\)", r"\\1", candidate)'
        echo '    candidate = re.sub(r"[`*_>#-]+", " ", candidate)'
        echo '    candidate = re.sub(r"\\s+", " ", candidate).strip()'
        echo '    if not candidate:'
        echo '        candidate = f"Slide {idx}"'
        echo '    return candidate.replace("\t", " ")[:100]'
        echo 'for idx, slide in enumerate(slides, 1):'
        echo '    print(f"{idx}\t{label_for(slide, idx)}")'
    end | python3 - "$deck_path"
end

function slide_label_for_index -a wanted_index
    for entry in $slide_catalog_lines
        set parts (string split \t -- "$entry")
        if test "$parts[1]" = "$wanted_index"
            echo "$parts[2]"
            return 0
        end
    end

    echo "Slide $wanted_index"
end

function write_checkpoint -a checkpoint_path slide_index slide_label run_mode interval_seconds deck_path
    set slide_label (string replace -a \t ' ' -- "$slide_label")
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$slide_index" \
        "$slide_label" \
        (date -u +"%Y-%m-%dT%H:%M:%SZ") \
        "$run_mode" \
        "$interval_seconds" \
        "$deck_path" > "$checkpoint_path"
end

function load_checkpoint -a checkpoint_path
    if not test -f "$checkpoint_path"
        return 1
    end

    set line (string trim -- (cat "$checkpoint_path"))
    if test -z "$line"
        return 1
    end

    string split \t -- "$line"
end

function deckset_launch -a deck_path run_mode start_slide return_app_id
    begin
        echo 'on run argv'
        echo '    set deckPathText to (item 1 of argv)'
        echo '    set runMode to (item 2 of argv)'
        echo '    set startSlide to (item 3 of argv) as integer'
        echo '    set returnAppId to (item 4 of argv)'
        echo '    set deckFile to POSIX file deckPathText'
        echo '    set targetDocument to missing value'
        echo ''
        echo '    tell application "Deckset"'
        echo '        activate'
        echo '        open deckFile'
        echo ''
        echo '        repeat 50 times'
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
        echo '            if not (exists document 1) then'
        echo '                error "Deckset did not open the presentation."'
        echo '            end if'
        echo '            set targetDocument to document 1'
        echo '        end if'
        echo ''
        echo '        tell targetDocument'
        echo '            set slideIndex to startSlide'
        echo '        end tell'
        echo ''
        echo '        if runMode is "rehearse" then'
        echo '            rehearse targetDocument'
        echo '        else'
        echo '            present targetDocument'
        echo '        end if'
        echo '        delay 0.5'
        echo '    end tell'
        echo ''
        echo '    if returnAppId is not "" then'
        echo '        tell application id returnAppId to activate'
        echo '    end if'
        echo 'end run'
    end | osascript - "$deck_path" "$run_mode" "$start_slide" "$return_app_id"
end

function deckset_set_slide -a deck_path slide_index
    begin
        echo 'on run argv'
        echo '    set deckPathText to (item 1 of argv)'
        echo '    set slideIndexValue to (item 2 of argv) as integer'
        echo '    set targetDocument to missing value'
        echo ''
        echo '    tell application "Deckset"'
        echo '        repeat with aDocument in documents'
        echo '            try'
        echo '                if POSIX path of (file of aDocument as alias) is deckPathText then'
        echo '                    set targetDocument to aDocument'
        echo '                    exit repeat'
        echo '                end if'
        echo '            end try'
        echo '        end repeat'
        echo ''
        echo '        if targetDocument is missing value then'
        echo '            if not (exists document 1) then'
        echo '                error "Deckset presentation is no longer open."'
        echo '            end if'
        echo '            set targetDocument to document 1'
        echo '        end if'
        echo ''
        echo '        tell targetDocument'
        echo '            set slideIndex to slideIndexValue'
        echo '        end tell'
        echo '    end tell'
        echo 'end run'
    end | osascript - "$deck_path" "$slide_index"
end

set script_dir (cd (dirname (status --current-filename)); pwd)
set repo_root (cd "$script_dir/.."; pwd)
set deckset_file "$repo_root/DECKSET.md"

set tmp_dir /tmp
if test -d "$repo_root/tmp"
    set tmp_dir "$repo_root/tmp"
end
set repo_name (basename "$repo_root")
set checkpoint_file "$tmp_dir/deckset-timer-$repo_name.tsv"

set mode total-time
set run_mode present
set start_mode beginning
set value ""
set value_provided 0
set skip_title 0
set dry_run 0

for arg in $argv
    switch $arg
        case -h --help
            show_help
            exit 0
        case --interval
            set mode interval
        case --total-time --total-time-mode
            set mode total-time
        case --present
            set run_mode present
        case --rehearse
            set run_mode rehearse
        case --pick
            set start_mode pick
        case --resume
            set start_mode resume
        case --no-skip-title
            set skip_title 0
        case --skip-title
            set skip_title 1
        case --dry-run
            set dry_run 1
        case '*'
            if test "$value_provided" -eq 0
                set value "$arg"
                set value_provided 1
            else
                error_msg "Unexpected argument: $arg"
                echo >&2
                show_help >&2
                exit 1
            end
    end
end

if not test -f "$deckset_file"
    error_msg "Could not find $deckset_file"
    exit 1
end

set -g slide_catalog_lines (slide_catalog "$deckset_file")
set slide_count (count $slide_catalog_lines)

if test "$slide_count" -eq 0
    error_msg "No slides found in $deckset_file"
    exit 1
end

set resume_fields
if test "$start_mode" = resume
    set resume_fields (load_checkpoint "$checkpoint_file")
    or begin
        error_msg "No checkpoint found at $checkpoint_file"
        exit 1
    end

    if test "$resume_fields[6]" != "$deckset_file"
        error_msg "Checkpoint file is for a different deck: $resume_fields[6]"
        exit 1
    end
end

if test "$value_provided" -eq 0
    if test "$start_mode" = resume
        set mode interval
        set value "$resume_fields[5]"
    else if set -q PRESENTATION_TIME
        set value "$PRESENTATION_TIME"
    else
        set value 25
    end
end

set requested_start_slide 1
set requested_start_label (slide_label_for_index 1)

switch $start_mode
    case pick
        if not command -sq gum
            error_msg "--pick requires gum"
            exit 1
        end

        set picked_line (printf '%s\n' $slide_catalog_lines | gum filter --placeholder "Pick a slide to start from")
        if test -z "$picked_line"
            error_msg "No slide selected"
            exit 1
        end

        set picked_parts (string split \t -- "$picked_line")
        set requested_start_slide "$picked_parts[1]"
        set requested_start_label "$picked_parts[2]"
    case resume
        set requested_start_slide "$resume_fields[1]"
        set requested_start_label "$resume_fields[2]"
end

set effective_start_slide "$requested_start_slide"
if test "$skip_title" -eq 1; and test "$requested_start_slide" -eq 1; and test "$slide_count" -gt 1
    set effective_start_slide 2
end

if test "$effective_start_slide" -lt 1; or test "$effective_start_slide" -gt "$slide_count"
    error_msg "Start slide out of range: $effective_start_slide"
    exit 1
end

set effective_start_label (slide_label_for_index "$effective_start_slide")
set timed_slide_count (math "$slide_count - $effective_start_slide + 1")

if test "$timed_slide_count" -le 0
    error_msg "No timed slides available."
    exit 1
end

set parsed_seconds ""
switch $mode
    case total-time
        set parsed_seconds (parse_duration_seconds "$value" minutes)
        or begin
            error_msg "Could not parse total presentation time: $value"
            exit 1
        end
    case interval
        set parsed_seconds (parse_duration_seconds "$value" seconds)
        or begin
            error_msg "Could not parse interval: $value"
            exit 1
        end
end

python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)' "$parsed_seconds"
or begin
    error_msg "Timing value must be greater than zero. Got: $value"
    exit 1
end

set interval_seconds ""
set total_seconds ""

switch $mode
    case total-time
        set total_seconds $parsed_seconds
        set interval_seconds (math -s 6 "$total_seconds / $timed_slide_count")
    case interval
        set interval_seconds $parsed_seconds
        set total_seconds (math -s 6 "$interval_seconds * $timed_slide_count")
end

set skip_title_text no
if test "$skip_title" -eq 1
    set skip_title_text yes
end

set start_gate_text no
if test "$run_mode" = present
    set start_gate_text yes
end

set interval_display (printf "%.2f" $interval_seconds)
set total_seconds_display (printf "%.2f" $total_seconds)
set total_minutes_display (printf "%.2f" (math "$total_seconds / 60"))

info_msg "Deckset timer"
echo "Mode: $run_mode"
echo "File: $deckset_file"
echo "Slides: $slide_count"
echo "Requested start slide: $requested_start_slide — $requested_start_label"
echo "Actual timed start slide: $effective_start_slide — $effective_start_label"
echo "Timed slides remaining: $timed_slide_count"
echo "Skip title slide: $skip_title_text"
echo "Start gate in terminal: $start_gate_text"
echo "Checkpoint file: $checkpoint_file"

switch $start_mode
    case resume
        echo "Recovery mode: resume"
    case pick
        echo "Recovery mode: pick"
end

switch $mode
    case total-time
        echo "Requested total time: $value"
        echo "Computed interval: $interval_display seconds per slide"
    case interval
        echo "Interval: $interval_display seconds per slide"
end

echo "Estimated remaining duration: $total_seconds_display seconds ($total_minutes_display minutes)"
echo

if test "$dry_run" -eq 1
    exit 0
end

set return_app_id ""
if test "$run_mode" = present
    set return_app_id (osascript -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' 2>/dev/null)
end

deckset_launch "$deckset_file" "$run_mode" "$effective_start_slide" "$return_app_id"
write_checkpoint "$checkpoint_file" "$effective_start_slide" "$effective_start_label" "$run_mode" "$interval_seconds" "$deckset_file"

if test "$run_mode" = present
    info_msg "Adjust monitors, then press any key here to start the timer."
    read --nchars 1 --silent _start_key
    echo
    info_msg "Timer started."
end

set current_slide "$effective_start_slide"
while test "$current_slide" -lt "$slide_count"
    sleep "$interval_seconds"
    set next_slide (math "$current_slide + 1")
    deckset_set_slide "$deckset_file" "$next_slide"
    set next_label (slide_label_for_index "$next_slide")
    write_checkpoint "$checkpoint_file" "$next_slide" "$next_label" "$run_mode" "$interval_seconds" "$deckset_file"
    set current_slide "$next_slide"
end

sleep "$interval_seconds"
