#!/bin/bash

# 🚀 Git Auto Push - 汎用自動プッシュツール with ゲーム要素！
# 使用方法: ./autopush.sh [カスタムメッセージ] [オプション]
# エイリアス: ap [カスタムメッセージ] [オプション]
# オプション: --info, --stats, --help, --game, --no-game, --quit-game

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
MAGENTA='\033[0;95m'
GOLD='\033[1;33m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 絵文字定義
ROCKET="🚀"
CHECK="✅"
PACKAGE="📦"
WARNING="⚠️"
INFO="ℹ️"
PENCIL="📝"
FIRE="🔥"
STAR="⭐"
TROPHY="🏆"
GEM="💎"
LIGHTNING="⚡"
CROWN="👑"
MEDAL="🥇"
SPARKLES="✨"
PARTY="🎉"
GAME="🎮"
BOOK="📚"
TERMINAL="💻"
BRANCH="🌿"
MERGE="🔀"
RESET="🔄"
TAG="🏷️"
STASH="📋"
GLOBE="🌐"
FOLDER="📁"
CLOCK="🕐"
USER="👤"

# データディレクトリとファイル
STATS_DIR="$HOME/.autopush"
STATS_FILE="$STATS_DIR/stats.txt"
BADGES_FILE="$STATS_DIR/badges.txt"
STREAK_FILE="$STATS_DIR/streak.txt"
CONFIG_FILE="$STATS_DIR/config.txt"

# データディレクトリを作成
mkdir -p "$STATS_DIR"

# 設定ファイルが存在しない場合は初期化（デフォルト：ゲームモードON）
if [ ! -f "$CONFIG_FILE" ]; then
    echo "game_mode=true" > "$CONFIG_FILE"
fi

# 設定読み込み
source "$CONFIG_FILE"

# ゲームモードフラグ（設定ファイルから読み込み）
GAME_MODE=$game_mode
CUSTOM_MSG=""
SHOW_INFO=false
SHOW_STATS=false
SHOW_HELP=false

# 引数解析
for arg in "$@"; do
    case $arg in
        --no-game)
            GAME_MODE=false
            shift
            ;;
        --game)
            GAME_MODE=true
            shift
            ;;
        --quit-game)
            echo "game_mode=false" > "$CONFIG_FILE"
            echo -e "${YELLOW}${INFO} ゲームモードを永続的に無効化しました${NC}"
            echo -e "${GRAY}再有効化するには --game フラグを使用してください${NC}"
            GAME_MODE=false
            shift
            ;;
        --info)
            SHOW_INFO=true
            shift
            ;;
        --stats)
            SHOW_STATS=true
            shift
            ;;
        --help|--commands)
            SHOW_HELP=true
            shift
            ;;
        *)
            if [ -z "$CUSTOM_MSG" ]; then
                CUSTOM_MSG="$arg"
            fi
            ;;
    esac
done

# ゲームモードが有効になった場合は設定を保存
if [ "$GAME_MODE" = true ] && [ "$game_mode" != "true" ]; then
    echo "game_mode=true" > "$CONFIG_FILE"
fi

# 統計ファイルが存在しない場合は初期化
if [ ! -f "$STATS_FILE" ]; then
    echo "total_pushes=0" > "$STATS_FILE"
    echo "level=1" >> "$STATS_FILE"
    echo "xp=0" >> "$STATS_FILE"
    echo "last_push_date=" >> "$STATS_FILE"
fi

# バッジファイルが存在しない場合は初期化
if [ ! -f "$BADGES_FILE" ]; then
    touch "$BADGES_FILE"
fi

# ストリークファイルが存在しない場合は初期化
if [ ! -f "$STREAK_FILE" ]; then
    echo "current_streak=0" > "$STREAK_FILE"
    echo "max_streak=0" >> "$STREAK_FILE"
    echo "last_streak_date=" >> "$STREAK_FILE"
fi

# 統計読み込み関数
load_stats() {
    source "$STATS_FILE"
}

# 統計保存関数
save_stats() {
    echo "total_pushes=$total_pushes" > "$STATS_FILE"
    echo "level=$level" >> "$STATS_FILE"
    echo "xp=$xp" >> "$STATS_FILE"
    echo "last_push_date=$last_push_date" >> "$STATS_FILE"
}

# ストリーク読み込み関数
load_streak() {
    source "$STREAK_FILE"
}

# ストリーク保存関数
save_streak() {
    echo "current_streak=$current_streak" > "$STREAK_FILE"
    echo "max_streak=$max_streak" >> "$STREAK_FILE"
    echo "last_streak_date=$last_streak_date" >> "$STREAK_FILE"
}

# レベル計算関数 (次のレベルに必要なXP = level * 100)
calculate_level() {
    local current_xp=$1
    local new_level=1
    local required_xp=100
    
    while [ $current_xp -ge $required_xp ]; do
        current_xp=$((current_xp - required_xp))
        new_level=$((new_level + 1))
        required_xp=$((new_level * 100))
    done
    
    echo $new_level
}

# コンパクトなリポジトリ情報表示
show_compact_info() {
    local current_branch=$(git branch --show-current 2>/dev/null)
    local remote_url=$(git remote get-url origin 2>/dev/null)
    
    if [ -n "$current_branch" ]; then
        echo -e "${BRANCH}${current_branch} ${GLOBE}$(basename "$remote_url" .git) ${GRAY}(--info で詳細)${NC}"
    fi
}

# リポジトリ情報表示関数
show_repo_info() {
    echo -e "${GLOBE}${CYAN} === リポジトリ情報 === ${NC}"
    
    # 現在のブランチ
    local current_branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$current_branch" ]; then
        echo -e "${BRANCH} ブランチ: ${GREEN}$current_branch${NC}"
    fi
    
    # リモートリポジトリ
    local remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -n "$remote_url" ]; then
        echo -e "${GLOBE} リモート: ${BLUE}$remote_url${NC}"
    fi
    
    # 最新コミット情報
    local latest_commit=$(git log --oneline -1 2>/dev/null)
    if [ -n "$latest_commit" ]; then
        echo -e "${PACKAGE} 最新コミット: ${PURPLE}$latest_commit${NC}"
    fi
    
    # リモートとの同期状態
    git fetch --dry-run &>/dev/null
    local ahead=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
    local behind=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        echo -e "${WARNING} 同期状態: ${YELLOW}$behind件進んでいて、$ahead件遅れています${NC}"
    elif [ "$ahead" -gt 0 ]; then
        echo -e "${INFO} 同期状態: ${YELLOW}リモートより$ahead件遅れています${NC}"
    elif [ "$behind" -gt 0 ]; then
        echo -e "${ROCKET} 同期状態: ${GREEN}リモートより$behind件進んでいます${NC}"
    else
        echo -e "${CHECK} 同期状態: ${GREEN}リモートと同期済み${NC}"
    fi
    
    # 作業ディレクトリの状態
    local staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
    local unstaged=$(git diff --name-only | wc -l | tr -d ' ')
    local untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
    
    if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        echo -e "${FOLDER} 作業状態: ${YELLOW}ステージ済み:$staged件 未ステージ:$unstaged件 未追跡:$untracked件${NC}"
    else
        echo -e "${FOLDER} 作業状態: ${GREEN}クリーン${NC}"
    fi
    
    # ユーザー情報
    local git_user=$(git config user.name 2>/dev/null)
    local git_email=$(git config user.email 2>/dev/null)
    if [ -n "$git_user" ]; then
        echo -e "${USER} ユーザー: ${WHITE}$git_user${NC} ${GRAY}<$git_email>${NC}"
    fi
    
    echo ""
}

# コンパクトゲーム統計
show_compact_game_stats() {
    if [ "$GAME_MODE" = true ]; then
        load_stats
        load_streak
        echo -e "${GAME}Lv.$level ${LIGHTNING}$xp XP ${FIRE}$current_streak日 ${ROCKET}$total_pushes回 ${GRAY}(--stats で詳細)${NC}"
    fi
}

# バッジ追加関数
add_badge() {
    local badge_name="$1"
    local badge_emoji="$2"
    local badge_desc="$3"
    
    if ! grep -q "$badge_name" "$BADGES_FILE" 2>/dev/null; then
        echo "$badge_name|$badge_emoji|$badge_desc" >> "$BADGES_FILE"
        if [ "$GAME_MODE" = true ]; then
            echo -e "${GOLD}${SPARKLES} 新しいバッジを獲得！ ${badge_emoji} ${badge_name}${NC}"
            echo -e "${CYAN}「${badge_desc}」${NC}"
            echo ""
        fi
    fi
}

# ストリーク更新関数
update_streak() {
    local today=$(date '+%Y-%m-%d')
    local yesterday=$(date -d "yesterday" '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d')
    
    load_streak
    
    if [ "$last_streak_date" = "$today" ]; then
        # 今日既にプッシュ済み - ストリーク変更なし
        return
    elif [ "$last_streak_date" = "$yesterday" ]; then
        # 昨日プッシュしていた - ストリーク継続
        current_streak=$((current_streak + 1))
    elif [ -z "$last_streak_date" ] || [ "$last_streak_date" != "$yesterday" ]; then
        # ストリークが途切れた、または初回
        current_streak=1
    fi
    
    # 最大ストリーク更新
    if [ $current_streak -gt $max_streak ]; then
        max_streak=$current_streak
    fi
    
    last_streak_date="$today"
    save_streak
}

# 励ましメッセージ配列
ENCOURAGEMENT_MESSAGES=(
    "素晴らしいコミットです！"
    "あなたのコードが世界を変える！"
    "今日も開発お疲れ様です！"
    "継続は力なり！"
    "次のレベルまであと少し！"
    "コードの魔法使いですね！"
    "開発スキルがレベルアップ！"
    "今日のプッシュも完璧です！"
    "あなたの情熱が感じられます！"
    "素晴らしい進歩です！"
    "コミットマスターの称号に近づいています！"
    "開発の神が微笑んでいます！"
)

# ランダム励ましメッセージ取得
get_encouragement() {
    local index=$((RANDOM % ${#ENCOURAGEMENT_MESSAGES[@]}))
    echo "${ENCOURAGEMENT_MESSAGES[$index]}"
}

# レベルアップ効果表示
show_levelup_effect() {
    echo -e "${GOLD}${CROWN}${CROWN}${CROWN} LEVEL UP! ${CROWN}${CROWN}${CROWN}${NC}"
    echo -e "${MAGENTA}${SPARKLES} レベル $level に到達しました！ ${SPARKLES}${NC}"
    echo ""
}

# Gitコマンドクイックリファレンス表示
show_git_commands() {
    echo -e "${BOOK}${CYAN} === Gitコマンドクイックリファレンス === ${NC}"
    echo -e "${TERMINAL} ${GREEN}基本操作:${NC}"
    echo -e "  ${YELLOW}git status${NC}          ${GRAY}# 現在の状態を確認${NC}"
    echo -e "  ${YELLOW}git log --oneline${NC}   ${GRAY}# コミット履歴を簡潔表示${NC}"
    echo -e "  ${YELLOW}git diff${NC}            ${GRAY}# 変更内容を確認${NC}"
    echo -e "  ${YELLOW}git add .${NC}           ${GRAY}# 全ての変更をステージング${NC}"
    
    echo -e "${BRANCH} ${GREEN}ブランチ操作:${NC}"
    echo -e "  ${YELLOW}git branch${NC}          ${GRAY}# ブランチ一覧表示${NC}"
    echo -e "  ${YELLOW}git checkout -b <名前>${NC} ${GRAY}# 新ブランチ作成・切り替え${NC}"
    echo -e "  ${YELLOW}git switch <ブランチ>${NC}  ${GRAY}# ブランチ切り替え${NC}"
    echo -e "  ${YELLOW}git merge <ブランチ>${NC}   ${GRAY}# ブランチをマージ${NC}"
    
    echo -e "${RESET} ${GREEN}取り消し操作:${NC}"
    echo -e "  ${YELLOW}git reset HEAD~1${NC}    ${GRAY}# 最新コミットを取り消し${NC}"
    echo -e "  ${YELLOW}git checkout .${NC}      ${GRAY}# 作業ディレクトリの変更を取り消し${NC}"
    echo -e "  ${YELLOW}git clean -fd${NC}       ${GRAY}# 未追跡ファイルを削除${NC}"
    
    echo -e "${STASH} ${GREEN}一時保存:${NC}"
    echo -e "  ${YELLOW}git stash${NC}           ${GRAY}# 変更を一時保存${NC}"
    echo -e "  ${YELLOW}git stash pop${NC}       ${GRAY}# 一時保存した変更を復元${NC}"
    echo -e "  ${YELLOW}git stash list${NC}      ${GRAY}# 一時保存一覧を表示${NC}"
    
    echo -e "${TAG} ${GREEN}リモート操作:${NC}"
    echo -e "  ${YELLOW}git pull${NC}            ${GRAY}# リモートから最新を取得${NC}"
    echo -e "  ${YELLOW}git fetch${NC}           ${GRAY}# リモート情報を取得（マージしない）${NC}"
    echo -e "  ${YELLOW}git remote -v${NC}       ${GRAY}# リモートリポジトリ一覧${NC}"
    
    echo -e "${GRAY}💡 オプション: --info (リポジトリ情報) --stats (ゲーム統計) --help (このヘルプ)${NC}"
    echo ""
}

# ゲーム統計表示
show_game_stats() {
    load_stats
    load_streak
    
    local next_level_xp=$(((level * 100)))
    local current_level_xp=$((xp - ((level - 1) * (level - 1) * 50)))
    local xp_progress=$((current_level_xp * 100 / next_level_xp))
    
    echo -e "${GAME}${CYAN} === ゲーム統計 === ${NC}"
    echo -e "${STAR} レベル: ${GOLD}$level${NC}"
    echo -e "${LIGHTNING} 経験値: ${YELLOW}$current_level_xp${NC}/${GOLD}$next_level_xp${NC} XP"
    echo -e "${FIRE} 現在のストリーク: ${RED}$current_streak${NC}日"
    echo -e "${TROPHY} 最大ストリーク: ${PURPLE}$max_streak${NC}日"
    echo -e "${ROCKET} 総プッシュ数: ${GREEN}$total_pushes${NC}回"
    
    # プログレスバー表示
    local bar_length=20
    local filled=$((xp_progress * bar_length / 100))
    local empty=$((bar_length - filled))
    local progress_bar=""
    
    for ((i=0; i<filled; i++)); do progress_bar+="█"; done
    for ((i=0; i<empty; i++)); do progress_bar+="░"; done
    
    echo -e "${CYAN}XP進歩: ${GOLD}[$progress_bar]${NC} ${xp_progress}%"
    
    # バッジ表示
    if [ -f "$BADGES_FILE" ] && [ -s "$BADGES_FILE" ]; then
        echo -e "${GEM} バッジ:"
        while IFS='|' read -r name emoji desc; do
            echo -e "  ${emoji} ${name}"
        done < "$BADGES_FILE"
    fi
    
    # ゲームモード終了のヒント
    echo -e "${GRAY}💡 ヒント: ${YELLOW}--quit-game${GRAY} フラグでゲームモードを永続的に無効化できます${NC}"
    echo ""
}

# バッジチェック関数
check_badges() {
    load_stats
    load_streak
    
    # プッシュ数バッジ
    case $total_pushes in
        1) add_badge "初心者" "🌱" "初めてのプッシュを完了" ;;
        10) add_badge "駆け出し開発者" "🚶" "10回のプッシュを達成" ;;
        50) add_badge "コミット戦士" "⚔️" "50回のプッシュを達成" ;;
        100) add_badge "プッシュマスター" "🥋" "100回のプッシュを達成" ;;
        500) add_badge "コード忍者" "🥷" "500回のプッシュを達成" ;;
        1000) add_badge "開発レジェンド" "🦄" "1000回のプッシュを達成" ;;
    esac
    
    # ストリークバッジ
    case $current_streak in
        3) add_badge "3日連続" "🔥" "3日連続でプッシュを実行" ;;
        7) add_badge "週間戦士" "📅" "7日連続でプッシュを実行" ;;
        30) add_badge "月間チャンピオン" "🗓️" "30日連続でプッシュを実行" ;;
        100) add_badge "ストリーク神" "⚡" "100日連続でプッシュを実行" ;;
    esac
    
    # レベルバッジ
    case $level in
        5) add_badge "レベル5到達" "🎖️" "レベル5に到達" ;;
        10) add_badge "レベル10到達" "🏅" "レベル10に到達" ;;
        25) add_badge "レベル25到達" "🏆" "レベル25に到達" ;;
        50) add_badge "レベル50到達" "👑" "レベル50に到達" ;;
        100) add_badge "レベル100到達" "💎" "レベル100に到達" ;;
    esac
}

# メインロジック開始
if [ "$GAME_MODE" = true ]; then
    echo -e "${CYAN}${GAME} Git Auto Push Tool${NC}"
else
    echo -e "${CYAN}${ROCKET} Git Auto Push Tool${NC}"
fi

# コンパクト表示（基本情報のみ）
show_compact_info
show_compact_game_stats

# オプション指定時の詳細表示
if [ "$SHOW_INFO" = true ]; then
    echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────${NC}"
    show_repo_info
fi

if [ "$SHOW_STATS" = true ] && [ "$GAME_MODE" = true ]; then
    echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────${NC}"
    show_game_stats
fi

if [ "$SHOW_HELP" = true ]; then
    echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────${NC}"
    show_git_commands
fi

# 情報表示のみの場合は終了
if [ "$SHOW_INFO" = true ] || [ "$SHOW_STATS" = true ] || [ "$SHOW_HELP" = true ]; then
    exit 0
fi

echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────${NC}"

# Git リポジトリかチェック
if [ ! -d ".git" ]; then
    echo -e "${RED}${WARNING} エラー: Git リポジトリではありません${NC}"
    echo -e "${YELLOW}${INFO} 'git init' を実行してください${NC}"
    exit 1
fi

# 変更があるかチェック
if git diff --quiet && git diff --staged --quiet; then
    echo -e "${YELLOW}${PENCIL} 変更がありません。プッシュする必要はありません。${NC}"
    exit 0
fi

# リモートが設定されているかチェック
if ! git remote get-url origin &>/dev/null; then
    echo -e "${RED}${WARNING} エラー: リモートリポジトリが設定されていません${NC}"
    echo -e "${YELLOW}${INFO} 'git remote add origin <URL>' を実行してください${NC}"
    exit 1
fi

echo -e "${BLUE}${ROCKET} === Git Push 開始 ===${NC}"

# 変更されたファイルを表示
echo -e "${BLUE}${INFO} 変更されたファイル:${NC}"
git status --porcelain | while read line; do
    echo -e "  ${GREEN}${line}${NC}"
done
echo ""

# カスタムメッセージが指定されていない場合、自動生成
if [ -z "$CUSTOM_MSG" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
    COMMIT_MSG="🔄 自動更新 - $TIMESTAMP"
else
    COMMIT_MSG="$CUSTOM_MSG"
fi

echo -e "${PACKAGE} ${CYAN}コミットメッセージ:${NC} ${COMMIT_MSG}"
echo ""

# 全ての変更をステージング
echo -e "${BLUE}${INFO} 変更をステージング中...${NC}"
git add -A

# コミット
echo -e "${BLUE}${INFO} コミット中...${NC}"
if git commit -m "$COMMIT_MSG"; then
    echo -e "${GREEN}${CHECK} コミット完了${NC}"
else
    echo -e "${RED}${WARNING} コミットに失敗しました${NC}"
    exit 1
fi

# プッシュ
echo -e "${BLUE}${INFO} リモートリポジトリにプッシュ中...${NC}"
if git push; then
    echo ""
    echo -e "${GREEN}${CHECK}${CHECK}${CHECK} 自動プッシュ完了！${CHECK}${CHECK}${CHECK}${NC}"
    echo -e "${PURPLE}Repository: $(git remote get-url origin)${NC}"
    echo -e "${PURPLE}Branch: $(git branch --show-current)${NC}"
    echo -e "${PURPLE}Commit: $(git rev-parse --short HEAD)${NC}"
    
    # ゲームモードの場合、統計更新と励ましメッセージ
    if [ "$GAME_MODE" = true ]; then
        echo ""
        echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GOLD}${SPARKLES} === ゲーム結果 === ${SPARKLES}${NC}"
        echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # 統計読み込み
        load_stats
        
        # 前のレベルを保存
        old_level=$level
        
        # 統計更新
        total_pushes=$((total_pushes + 1))
        xp=$((xp + 50))  # プッシュごとに50XP
        last_push_date=$(date '+%Y-%m-%d')
        
        # レベル再計算
        level=$(calculate_level $xp)
        
        # ストリーク更新
        update_streak
        
        # 統計保存
        save_stats
        
        # レベルアップチェック
        if [ $level -gt $old_level ]; then
            show_levelup_effect
        fi
        
        # バッジチェック
        check_badges
        
        # 励ましメッセージ
        echo -e "${SPARKLES} ${MAGENTA}$(get_encouragement)${NC}"
        echo -e "${PARTY} ${GOLD}+50 XP獲得！${NC}"
        
        # ストリーク表示
        load_streak
        if [ $current_streak -gt 1 ]; then
            echo -e "${FIRE} ${RED}$current_streak日連続プッシュ！${NC}"
        fi
        
        echo ""
        echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
else
    echo -e "${RED}${WARNING} プッシュに失敗しました${NC}"
    exit 1
fi
