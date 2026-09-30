#!/usr/bin/env bash
# Work-tools paths and defaults, in one place. Sourced by mybashrc and the setup scripts.
# Values already set in the environment win, so any of these can be overridden.

: "${WORK_TOOLS_DIR:=$HOME/my_work_tools}"
: "${WORK_ENV_DIR:=$HOME/Work_Environments}"
: "${GLOBAL_ENV_DIR:=$WORK_TOOLS_DIR/global_env}"
: "${BIN_DIR:=$WORK_TOOLS_DIR/bin}"
: "${SSH_DIR:=$HOME/.ssh}"
: "${GITHUB_OWNER:=jconwell3115}"
# Optional private overlay (work-only functions, aliases and config); everything that uses it
# checks it exists, so machines without it just skip it
: "${GLOBAL_ENV_OVERLAY_DIR:=$WORK_TOOLS_DIR/global_env_work}"

export WORK_TOOLS_DIR WORK_ENV_DIR GLOBAL_ENV_DIR BIN_DIR SSH_DIR GITHUB_OWNER GLOBAL_ENV_OVERLAY_DIR
