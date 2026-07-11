# hyprdark — oh-my-zsh theme (Catppuccin Mocha, truecolor)

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{#a6adc8}on%f %F{#b4befe} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{#f9e2af}✗%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{#a6e3a1}✓%f"

# ssh sessions show user@host, local shells stay minimal
_host=""
if [[ -n "$SSH_CONNECTION" ]]; then
    _host="%F{#fab387}%n@%m%f "
fi

PROMPT='%F{#cba6f7}╭─%f ${_host}%F{#89b4fa}%~%f$(git_prompt_info)
%F{#cba6f7}╰─%f %(?.%F{#cba6f7}.%F{#f38ba8})❯%f '

RPROMPT='%(?..%F{#f38ba8}✘ %?%f)'
