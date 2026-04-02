FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# ─── System packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    zsh \
    tmux \
    neovim \
    bat \
    git \
    curl \
    wget \
    unzip \
    ripgrep \
    fd-find \
    jq \
    make \
    gcc \
    g++ \
    ca-certificates \
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# bat is installed as batcat on Ubuntu — symlink it
RUN ln -sf /usr/bin/batcat /usr/local/bin/bat

# ─── Docker CLI ───────────────────────────────────────────────────
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# ─── Node 20 ─────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ─── Python 3 ────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ─── PHP 8.5 + Composer ──────────────────────────────────────────
RUN add-apt-repository ppa:ondrej/php -y \
    && apt-get update \
    && apt-get install -y \
    php8.5-cli \
    php8.5-common \
    php8.5-mbstring \
    php8.5-xml \
    php8.5-curl \
    php8.5-zip \
    php8.5-mysql \
    php8.5-pgsql \
    php8.5-sqlite3 \
    php8.5-redis \
    php8.5-gd \
    php8.5-intl \
    php8.5-bcmath \
    php8.5-tokenizer \
    php8.5-dom \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# ─── Claude Code ──────────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ─── Set zsh as default shell ─────────────────────────────────────
RUN chsh -s /usr/bin/zsh root

# ─── Oh My Zsh + Powerlevel10k + plugins ─────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# ─── Tmux Plugin Manager ─────────────────────────────────────────
RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# ─── Dotfiles: zsh ───────────────────────────────────────────────
COPY config/zshrc /root/.zshrc
COPY config/p10k.zsh /root/.p10k.zsh

# ─── Dotfiles: tmux ──────────────────────────────────────────────
COPY config/tmux.conf /root/.tmux.conf

# ─── Dotfiles: nvim ──────────────────────────────────────────────
COPY config/nvim/ /root/.config/nvim/

# ─── Install tmux plugins ────────────────────────────────────────
RUN ~/.tmux/plugins/tpm/bin/install_plugins || true

# ─── Install nvim plugins headlessly ─────────────────────────────
RUN nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

# ─── Workspace ────────────────────────────────────────────────────
WORKDIR /app

ENTRYPOINT ["/usr/bin/zsh"]
