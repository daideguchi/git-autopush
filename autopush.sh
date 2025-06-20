#!/bin/bash

# 🚀 Git Auto Push - 汎用自動プッシュツール with ゲーム要素！
# 使用方法: ./autopush.sh [カスタムメッセージ] [オプション]
# エイリアス: ap [カスタムメッセージ] [オプション]
# オプション: --info, --stats, --help, --game, --no-game, --quit-game
#           --notifications, --badges, --profile, --report, --notify-slack

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
BELL="🔔"
CAMERA="📸"
CHART="📊"

# データディレクトリとファイル
STATS_DIR="$HOME/.autopush"
STATS_FILE="$STATS_DIR/stats.txt"
BADGES_FILE="$STATS_DIR/badges.txt"
STREAK_FILE="$STATS_DIR/streak.txt"
CONFIG_FILE="$STATS_DIR/config.txt"
BADGES_DIR="$STATS_DIR/badges"
REPORTS_DIR="$STATS_DIR/reports"

# データディレクトリを作成
mkdir -p "$STATS_DIR" "$BADGES_DIR" "$REPORTS_DIR"

# 設定ファイルが存在しない場合は初期化（デフォルト：ゲームモードON、通知ON）
if [ ! -f "$CONFIG_FILE" ]; then
    echo "game_mode=true" > "$CONFIG_FILE"
    echo "notifications=true" >> "$CONFIG_FILE"
    echo "badges_generation=false" >> "$CONFIG_FILE"
    echo "profile_update=false" >> "$CONFIG_FILE"
    echo "report_generation=false" >> "$CONFIG_FILE"
    echo "slack_notifications=false" >> "$CONFIG_FILE"
fi

# 設定読み込み
source "$CONFIG_FILE"

# フラグ変数
GAME_MODE=$game_mode
CUSTOM_MSG=""
SHOW_INFO=false
SHOW_STATS=false
SHOW_HELP=false
ENABLE_NOTIFICATIONS=${notifications:-true}
ENABLE_BADGES=${badges_generation:-false}
ENABLE_PROFILE=${profile_update:-false}
ENABLE_REPORT=${report_generation:-false}
ENABLE_SLACK=${slack_notifications:-false}

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
        --notifications)
            ENABLE_NOTIFICATIONS=true
            shift
            ;;
        --no-notifications)
            ENABLE_NOTIFICATIONS=false
            shift
            ;;
        --badges)
            ENABLE_BADGES=true
            shift
            ;;
        --profile)
            ENABLE_PROFILE=true
            shift
            ;;
        --report)
            ENABLE_REPORT=true
            shift
            ;;
        --notify-slack)
            ENABLE_SLACK=true
            shift
            ;;
        --enable-all)
            ENABLE_NOTIFICATIONS=true
            ENABLE_BADGES=true
            ENABLE_PROFILE=true
            ENABLE_REPORT=true
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

# デスクトップ通知送信
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Glass}"
    
    if [ "$ENABLE_NOTIFICATIONS" = true ]; then
        # macOS
        if command -v osascript >/dev/null 2>&1; then
            osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
        # Linux with notify-send
        elif command -v notify-send >/dev/null 2>&1; then
            notify-send "$title" "$message"
        fi
    fi
}

# SVGバッジ生成
generate_badge() {
    local badge_type="$1"
    local value="$2"
    local color="$3"
    local file_path="$BADGES_DIR/${badge_type}.svg"
    
    if [ "$ENABLE_BADGES" = true ]; then
        cat > "$file_path" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="120" height="20">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="a">
    <rect width="120" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#a)">
    <path fill="#555" d="M0 0h63v20H0z"/>
    <path fill="$color" d="M63 0h57v20H63z"/>
    <path fill="url(#b)" d="M0 0h120v20H0z"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="110">
    <text x="325" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="530">${badge_type}</text>
    <text x="325" y="140" transform="scale(.1)" textLength="530">${badge_type}</text>
    <text x="905" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="470">${value}</text>
    <text x="905" y="140" transform="scale(.1)" textLength="470">${value}</text>
  </g>
</svg>
EOF
        echo -e "${CAMERA} SVGバッジ生成: ${file_path}"
    fi
}

# GitHub Profile README用Markdown生成
generate_profile_markdown() {
    if [ "$ENABLE_PROFILE" = true ]; then
        load_stats
        load_streak
        
        local profile_file="$STATS_DIR/profile-stats.md"
        cat > "$profile_file" << EOF
## 🚀 Git Auto Push Stats

![Level](https://img.shields.io/badge/Level-${level}-gold?style=flat-square&logo=star)
![XP](https://img.shields.io/badge/XP-${xp}-blue?style=flat-square&logo=lightning)
![Streak](https://img.shields.io/badge/Streak-${current_streak}days-red?style=flat-square&logo=fire)
![Total Pushes](https://img.shields.io/badge/Pushes-${total_pushes}-green?style=flat-square&logo=git)

### 🏆 Recent Achievements
EOF
        
        if [ -f "$BADGES_FILE" ] && [ -s "$BADGES_FILE" ]; then
            while IFS='|' read -r name emoji desc; do
                echo "- $emoji **$name**: $desc" >> "$profile_file"
            done < "$BADGES_FILE"
        fi
        
        echo -e "${GLOBE} Profile Markdown生成: ${profile_file}"
    fi
}

# HTML統計レポート生成
generate_html_report() {
    if [ "$ENABLE_REPORT" = true ]; then
        load_stats
        load_streak
        
        local html_file="$REPORTS_DIR/stats-$(date '+%Y%m%d').html"
        cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🚀 Git Auto Push Statistics</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin: 0; padding: 20px; color: white; }
        .container { max-width: 800px; margin: 0 auto; background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border-radius: 20px; padding: 30px; box-shadow: 0 8px 32px rgba(0,0,0,0.3); }
        .header { text-align: center; margin-bottom: 30px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 30px 0; }
        .stat-card { background: rgba(255,255,255,0.2); padding: 20px; border-radius: 15px; text-align: center; }
        .stat-value { font-size: 2em; font-weight: bold; color: #ffd700; }
        .progress-bar { background: rgba(0,0,0,0.3); height: 20px; border-radius: 10px; overflow: hidden; margin: 10px 0; }
        .progress-fill { background: linear-gradient(90deg, #00ff88, #00ccff); height: 100%; transition: width 0.3s ease; }
        .badges { display: flex; flex-wrap: wrap; gap: 10px; justify-content: center; margin-top: 20px; }
        .badge { background: rgba(255,255,255,0.2); padding: 8px 16px; border-radius: 20px; font-size: 14px; }
        .timestamp { text-align: center; opacity: 0.7; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Git Auto Push Statistics</h1>
            <p>Your development journey in numbers</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">Lv.${level}</div>
                <div>レベル</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${xp}</div>
                <div>経験値</div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: $((xp % 100))%"></div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${current_streak}</div>
                <div>🔥 現在のストリーク</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${total_pushes}</div>
                <div>🚀 総プッシュ数</div>
            </div>
        </div>
        
        <div class="badges">
EOF
        
        if [ -f "$BADGES_FILE" ] && [ -s "$BADGES_FILE" ]; then
            while IFS='|' read -r name emoji desc; do
                echo "            <div class=\"badge\">$emoji $name</div>" >> "$html_file"
            done < "$BADGES_FILE"
        fi
        
        cat >> "$html_file" << EOF
        </div>
        
        <div class="timestamp">
            Generated on $(date '+%Y-%m-%d %H:%M:%S')
        </div>
    </div>
</body>
</html>
EOF
        
        echo -e "${CHART} HTML レポート生成: ${html_file}"
        
        # 自動でブラウザを開く
        if command -v open >/dev/null 2>&1; then
            open "$html_file" 2>/dev/null
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$html_file" 2>/dev/null
        fi
    fi
}

# Slack通知送信
send_slack_notification() {
    local webhook_url="$SLACK_WEBHOOK_URL"
    local message="$1"
    
    if [ "$ENABLE_SLACK" = true ] && [ -n "$webhook_url" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$webhook_url" 2>/dev/null
    fi
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
            
            # 通知送信
            send_notification "🏆 新バッジ獲得!" "$badge_emoji $badge_name: $badge_desc"
            
            # Slack通知
            send_slack_notification "🏆 *新バッジ獲得!* $badge_emoji *$badge_name*: $badge_desc"
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
    
    # レベルアップ通知
    send_notification "🎉 レベルアップ!" "おめでとうございます！レベル $level に到達しました！" "Sosumi"
    
    # Slack通知
    send_slack_notification "🎉 *レベルアップ!* おめでとうございます！レベル *$level* に到達しました！"
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
    
    echo -e "${BELL} ${GREEN}視覚的機能:${NC}"
    echo -e "  ${YELLOW}--notifications${NC}     ${GRAY}# デスクトップ通知有効${NC}"
    echo -e "  ${YELLOW}--badges${NC}            ${GRAY}# SVGバッジ生成${NC}"
    echo -e "  ${YELLOW}--profile${NC}           ${GRAY}# GitHub Profile用Markdown生成${NC}"
    echo -e "  ${YELLOW}--report${NC}            ${GRAY}# HTML統計レポート生成${NC}"
    echo -e "  ${YELLOW}--enable-all${NC}        ${GRAY}# 全視覚的機能有効${NC}"
    
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

# 視覚的機能実行
execute_visual_features() {
    if [ "$GAME_MODE" = true ]; then
        load_stats
        load_streak
        
        # SVGバッジ生成
        if [ "$ENABLE_BADGES" = true ]; then
            generate_badge "Level" "$level" "#ffd700"
            generate_badge "XP" "$xp" "#00ccff"
            generate_badge "Streak" "${current_streak}days" "#ff4444"
            generate_badge "Pushes" "$total_pushes" "#00ff88"
        fi
        
        # Profile Markdown生成
        generate_profile_markdown
        
        # HTML レポート生成
        generate_html_report
    fi
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
        
        # 視覚的機能実行
        execute_visual_features
        
        # 励ましメッセージ
        echo -e "${SPARKLES} ${MAGENTA}$(get_encouragement)${NC}"
        echo -e "${PARTY} ${GOLD}+50 XP獲得！${NC}"
        
        # 基本通知
        send_notification "🚀 Git Push 完了!" "$(get_encouragement) (+50 XP)"
        
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
