# hyprdark — oh-my-zsh theme (monochrome, truecolor)
# Shows: user @ host, cwd, git branch + state — always.

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{#6a6a6a}on%f %F{#c9c9c9} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{#ffffff}✗%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{#8a8a8a}✓%f"

PROMPT='%F{#ffffff}%B%n%b%f%F{#5a5a5a}@%f%F{#b8b8b8}%m%f %F{#6a6a6a}in%f %F{#e6e6e6}%~%f$(git_prompt_info)
%(?.%F{#e6e6e6}.%F{#ffffff})❯%f '

RPROMPT='%(?..%F{#9a9a9a}✘ %?%f)'
