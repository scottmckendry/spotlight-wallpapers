# Spotlight Wallpaper - Dev Commands
# https://danklinux.com/docs/dankmaterialshell/plugin-development#live-development

plugin_id := "spotlight-wallpapers"
plugin_dir := "~/.config/DankMaterialShell/plugins/spotlight-wallpapers"
repo_dir := justfile_directory()

# default: list available commands
default:
    @just --list

# symlink plugin into DMS plugins dir for live dev
link:
    rm -rf {{plugin_dir}}
    ln -s {{repo_dir}} {{plugin_dir}}

# remove symlink
unlink:
    rm -f {{plugin_dir}}

# reload plugin at runtime (no DMS restart needed)
reload:
    dms ipc call plugins reload {{plugin_id}}

# list all plugins and their status
list:
    dms ipc call plugins list

# link + reload in one shot
dev: link reload
