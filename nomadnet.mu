#!/usr/bin/env python3
# -*- coding: utf-8 -*-
print("#!c=0")

######## ИМПОРТ МОДУЛЕЙ: ######## 
import os, sys, json, time, random, re, sqlite3

######## ИНИЦИАЛИЗАЦИЯ ЛОГА (ЛОКАЛЬНЫЕ СИСТЕМНЫЕ ИНФОРМАЦИОННЫЕ СООБЩЕНИЯ) #####
log = []

######## СИСТЕМНЫЕ И ФАЙЛОВЫЕ ПУТИ ######## 
DB_PATH = os.path.join(os.path.dirname(__file__), "chatusers.db")
EMO_DB = os.path.join(os.path.dirname(__file__), "emoticons.txt")

######## СОЗДАНИЕ БД ЕСЛИ ОТСУТСТВУЕТ (обычно при первом запуске) ######
if not os.path.exists(DB_PATH):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            remote_identity TEXT,
            dest TEXT,
            display_name TEXT
        );
    """)
    conn.commit()
    conn.close()

######## НАСТРОЙКИ ЛИМИТА ОТОБРАЖЕНИЯ: ######## (Сохраняет интерфейс фиксированным в браузере meshchat)
MAX_CHARS = 160  # Настройте по необходимости для разбиения сообщений после N символов, 160 по умолчанию для nomadnet
MAX_LINES = 28   # Максимум строк на экране, для Meshchat 
DISPLAY_LIMIT = 36 # Максимум строк на экране, для Nomadnet

######## НАСТРОЙКИ ГЛАВНОГО СИСТЕМНОГО АДМИНИСТРАТОРА ######## (ИСПОЛЬЗУЙТЕ СЛОЖНЫЕ НИКНЕЙМЫ ДЛЯ СИСТЕМНЫХ АДМИНИСТРАТОРОВ!)
SYSADMIN = "setyouradminlognamehere" # УСТАНОВИТЕ ВАШ НИКНЕЙМ ГЛАВНОГО АДМИНИСТРАТОРА ДЛЯ АДМИНИСТРАТИВНЫХ КОМАНД ЧАТА

######## ЭМОДЗИ ИНТЕРФЕЙСА UNICODE: ######## 
user_icon = "\U0001F464" # "\U0001F464" # "\U0001F465" - "\U0001FAAA"
message_icon = "\U0001F4AC" 
msg2_icon = "\u2709\ufe0f"
send_icon = "\U0001F4E4"
totmsg_icon = "\U0001F4E9"
reload_icon = "\u21BB"
setup_icon = "\u2699\ufe0f"
cmd_icon = "\U0001F4BB" # \U0001F579
nickset_icon = "\U0001F504"
info_icon = "\u1F6C8"
stats_icon = "\u1F4DD"

######## Фильтры антиспама: ######## (Добавьте или удалите то, что хотите разрешить или запретить)
spam_patterns = [
    r"buy\s+now",
    r"free\s+money",
    r"fr[e3]{2}\s+m[o0]ney",
    r"click\s+here",
    r"cl[i1]ck\s+h[e3]re",
    r"subscribe\s+(now|today)",
    r"win\s+big",
    r"w[i1]n\s+b[i1]g",
    r"limited\s+offer",
    r"act\s+now",
    r"get\s+rich\s+quick",
    r"make\s+money\s+fast",
    r"easy\s+cash",
    r"work\s+from\s+home",
    r"double\s+your\s+income",
    r"guaranteed\s+results",
    r"risk[-\s]*free",
    r"lowest\s+price",
    r"no\s+credit\s+check",
    r"instant\s+approval",
    r"earn\s+\$\d+",
    r"cheap\s+meds",
    r"online\s+pharmacy",
    r"lose\s+weight\s+fast",
    r"miracle\s+cure",
    r"bitcoin\s+offer",
    r"b[i1]tcoin\s+deal",
    r"earn\s+bitcoin",
    r"make\s+money\s+with\s+bitcoin",
    r"crypto\s+investment",
    r"crypto\s+deal",
    r"get\s+rich\s+with\s+crypto",
    r"eth[e3]reum\s+promo",
    r"buy\s+crypto\s+now",
    r"invest\s+in\s+(crypto|bitcoin|ethereum)",
    r"\bfree\s+(bitcoin|crypto|ethereum)\b",
    r"\bsell\s+(bitcoin|crypto|ethereum)\b",
    r"\bi\s+sell\s+(bitcoin|bitcoins|crypto|ethereum)\b",
    r"\bbuy\s+(bitcoin|crypto|ethereum)\b",
    r"\bget\s+(bitcoin|crypto|ethereum)\b",
    r"\bmake\s+money\s+(with|from)\s+(bitcoin|crypto|ethereum)\b",
    r"\binvest\s+(in|into)\s+(bitcoin|crypto|ethereum)\b",
    r"\bbitcoin\s+(promo|deal|offer|discount)\b",
    r"\bcrypto\s+(promo|deal|offer|discount)\b",
    r"\bfree\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"\b(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\s+for\s+you\b",
    r"\bsell\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"\bbuy\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"\bi\s+sell\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"\bget\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"\bmake\s+money\s+(with|from)\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"\binvest\s+(in|into)\s+(bitcoin|bitcoins|coin|coins|crypto|tokens|ethereum)\b",
    r"(?:\W|^)(bitcoin|bitcoins|crypto|ethereum|tokens|coins)(?:\W|$)",
    r"\b(bitcoin|bitcoins|crypto|ethereum|tokens|coins)\s+for\s+(free|you)\b",
    r"\bfree\s+(bitcoin|bitcoins|crypto|ethereum|tokens|coins)\b",
    r"\bget\s+(bitcoin|bitcoins|crypto|ethereum|tokens|coins)\b",
    r"\bmake\s+money\s+(with|from)\s+(bitcoin|bitcoins|crypto|ethereum|tokens|coins)\b",
    r"\b(sex|porn|xxx|nude|nudes|nsfw|onlyfans|camgirl|camgirls|adult\s+video|erotic|blowjob|anal|fetish|strip|escort|hardcore|incest|milf|hentai|boobs|naked|cumshot|threesome|gangbang|squirting|deepthroat)\b",
    r"\b(pornhub|xvideos|redtube|xnxx|xhamster|cam4|chaturbate|brazzers|bangbros|spankbang|fleshlight|adultfriendfinder|livejasmin|myfreecams|stripchat|sex.com)\b",
    r"\bwatch\s+(live\s+)?(sex|porn|camgirls|nudes)\b",
    r"\bfree\s+(porn|cams|nudes|xxx|sex\s+videos)\b",
    r"\bhot\s+(girls|milfs|teens|models)\s+(live|online|waiting)\b",
    r"\bclick\s+(here|link)\s+(for|to)\s+(sex|porn|nudes|xxx|cam)\b",
    r"\b(see|watch|join)\s+(my|our)?\s*(onlyfans|cam|sex\s+show)\b",
    r"\b(win(?:ner)?|guaranteed|prize|cash|credit|loan|investment|rich|easy\s+money|urgent)\b",
    r"\b(click\s+here|act\s+now|limited\s+time|exclusive\s+deal|verify\s+your\s+account|update\s+required|login\s+now|reset\s+password)\b",
    r"\b(discount|sale|offer|promo|buy\s+now|order\s+today|lowest\s+price|cheap|bargain|deal)\b",
    r"\b(bit\.ly|tinyurl\.com|goo\.gl|freegift|get-rich|fastcash|adult|xxx|cams|nudes)\b",
    r"\b(make\s+\$\d{2,}|earn\s+\$\d{2,}|work\s+from\s+home|no\s+experience\s+needed)\b",
    r"\b(earn|make)\s+(money|cash)\s+(from\s+home|online|fast|easily)\b",
    r"\b(work\s+from\s+home|no\s+experience\s+needed|easy\s+income|passive\s+income)\b",
    r"\b(start\s+earning|get\s+paid\s+daily|quick\s+cash|instant\s+money)\b",
    r"\b(earn|make)\s+(money|cash)\s+(from|at)\s+home\b",
    r"\b(work\s+(from|at)\s+home|easy\s+income|passive\s+income)\b",
    r"\b(start\s+earning|get\s+paid\s+(daily|instantly)|quick\s+cash|instant\s+money)\b",
    r"\b(work\s+(from|at)\s+home|easy\s+income|passive\s+income|get\s+paid\s+(daily|instantly)|quick\s+cash|instant\s+money)\b",
    r"\b(earn|make|get)\s+(money|cash|income)\s*(now|fast|quickly|easily)?\b",
    r"\b(passive\s+income|easy\s+money|no\s+experience|required|work\s+online|get\s+paid\s+(daily|instantly))\b",
    r"\b(earn|make|receive)\s+(some\s+)?(money|cash|income|profit|revenue)\b",

]

################### Система автоматической окраски никнеймов ##################### (Измените цвета по вашим предпочтениям)
colors = [ "B900", "B090", "B009", "B099", "B909", "B066", "B933", "B336", "B939", "B660", "B030", "B630", "B363", "B393", "B606", "B060", "B003", "B960", "B999", "B822", "B525", "B255", "B729", "B279", "B297", "B972", "B792", "B227", "B277", "B377", "B773", "B737", "B003", "B111", "B555", "B222", "B088", "B808", "B180" ]
def get_color(name):
    return colors[sum(ord(c) for c in name.lower()) % len(colors)]


#########  Восстановление ввода из переменных окружения ОС ######## 
def recover_input(key_suffix):
    for k, v in os.environ.items():
        if k.lower().endswith(key_suffix):
            return v.strip()
    return ""

raw_username     = recover_input("username")
message          = recover_input("message")
remote_identity  = recover_input("remote_identity")
nickname         = recover_input("field_username")
dest             = recover_input("dest")

# Резервный вариант: аргументы командной строки при необходимости
if not raw_username and len(sys.argv) > 1:
    raw_username = sys.argv[1].strip()
if not message and len(sys.argv) > 2:
    message = sys.argv[2].strip()
if not dest and len(sys.argv) > 3:
    dest = sys.argv[3].strip()

# Извлечение хэш-кода из удалённой идентичности и адреса LXMF
hash_code = remote_identity[-4:] if remote_identity else ""
dest_code = dest[-4:] if dest else ""

# Умный резервный вариант для отображаемого имени с логированием
if nickname:
    display_name = nickname
elif dest:
    display_name = f"Guest_{dest_code}"
else:
    display_name = "Guest"

# Привязка никнейма к SQL БД и восстановление

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_identity TEXT,
            dest TEXT UNIQUE NOT NULL,
            display_name TEXT
        )
    """)
    conn.commit()
    conn.close()

def get_display_name_from_db(dest):
    if not dest:
        return None
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT display_name FROM users WHERE dest = ?", (dest,))
    result = cursor.fetchone()
    conn.close()
    return result[0] if result else None

def save_user_to_db(remote_identity, dest, display_name):
    if not remote_identity or not dest:
        return  # Don't save if required info is missing
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO users (remote_identity, dest, display_name)
        VALUES (?, ?, ?)
        ON CONFLICT(dest) DO UPDATE SET
            remote_identity = excluded.remote_identity,
            display_name = excluded.display_name
    """, (remote_identity, dest, display_name))
    conn.commit()
    conn.close()

# Initialize DB
init_db()

# Get environment variables
nickname = os.getenv("field_username", "").strip()
dest = os.getenv("dest", "").strip()
remote_identity = os.getenv("remote_identity", "").strip()

# Try to load display_name from DB
db_display_name = get_display_name_from_db(dest)

# Определение финального display_name с логированием
nickname_recovered_from_db = False

if nickname:
    display_name = nickname
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": f"`!` Никнейм восстановлен из окружения: {display_name} `!`"
    })
elif db_display_name:
    display_name = db_display_name
    nickname_recovered_from_db = True
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": f"`!` Никнейм восстановлен из базы данных: {display_name} `!`"
    })
elif dest:
    display_name = f"Guest_{dest[-4:]}"
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": f"`!` Никнейм не найден. Используется отпечаток: {display_name} `!`"
    })
else:
    display_name = "Guest"
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": "`!` Никнейм или отпечаток не найдены. Используется по умолчанию: Guest `!`"
    })

# Сохранение пользователя в БД если валидно
save_user_to_db(remote_identity, dest, display_name)

# -----------------------------------------------

safe_username = (
    raw_username.replace("`", "").replace("<", "").replace(">", "")
    .replace("\n", "").replace("\r", "").replace('"', "").replace("'", "")
    .replace("/", "").replace("\\", "").replace(";", "").replace(":", "")
    .replace("&", "").replace("=", "").replace("{", "").replace("}", "")
    .replace("[", "").replace("]", "").replace("(", "").replace(")", "")
    .replace("\t", "").replace("*", "").replace("+", "").replace("%", "")
    .replace("#", "").replace("^", "").replace("~", "").replace("|", "")
    .replace("$", "").replace(" ", "").strip() or "Guest"
)

# Функции темы чата
topic_file = os.path.join(os.path.dirname(__file__), "topic.json")
try:
    with open(topic_file, "r") as tf:
        topic_data = json.load(tf)
        topic_text = topic_data.get("text", "Добро пожаловать в чат!")
        topic_author = topic_data.get("user", "System")
except:
    topic_text = "Добро пожаловать в чат!"
    topic_author = "System"


log_file = os.path.join(os.path.dirname(__file__), "chat_log.json")
debug = []

try:
    with open(log_file, "r") as f:
        log = json.load(f)
        debug.append(f" Всего {len(log)} сообщений")
except Exception as e:
    log = []
    debug.append(f"Ошибка загрузки лога: {e}")

# ЛОГИКА КОМАНД ПОЛЬЗОВАТЕЛЯ:
cmd = message.strip().lower()


##### АДМИНИСТРАТИВНЫЕ КОМАНДЫ #####
if safe_username == SYSADMIN and cmd.startswith("/clear"):
    parts = cmd.split()

    if len(parts) == 1:
        # /clear ? удалить последнее сообщение
        if log:
            removed = log.pop()
            debug.append(f"Удалено последнее сообщение: <{removed['user']}> {removed['text']}")
        else:
            debug.append("Нет сообщений для очистки.")

    elif len(parts) == 2 and parts[1].isdigit():
        # /clear N ? удалить последние N сообщений
        count = int(parts[1])
        removed_count = 0
        while log and removed_count < count:
            removed = log.pop()
            debug.append(f"Удалено: <{removed['user']}> {removed['text']}")
            removed_count += 1
        debug.append(f"Очищено последних {removed_count} сообщений.")

    elif len(parts) == 3 and parts[1] == "user":
        # /clear user NICKNAME ? удалить все сообщения от этого пользователя
        target_user = parts[2]
        original_len = len(log)
        log[:] = [msg for msg in log if msg.get("user") != target_user]
        removed_count = original_len - len(log)
        debug.append(f"Очищено {removed_count} сообщений от пользователя '{target_user}'.")

    else:
        debug.append("Неверный синтаксис /clear. Используйте /clear, /clear N или /clear user NICKNAME.")

    # Сохранение обновлённого лога
    try:
        with open(log_file, "w", encoding="utf-8") as f:
            json.dump(log, f, indent=2, ensure_ascii=False)
        debug.append("Лог обновлён после очистки.")
    except Exception as e:
        debug.append(f"Ошибка команды Clear: {e}")

elif safe_username == SYSADMIN and cmd == "/clearall":
    if log:
        log.clear()
        debug.append("Все сообщения очищены администратором.")
        try:
            with open(log_file, "w", encoding="utf-8") as f:
                json.dump(log, f, indent=2, ensure_ascii=False)
            debug.append("Лог успешно очищен.")
        except Exception as e:
            debug.append(f"Ошибка ClearAll: {e}")
    else:
        debug.append("Лог уже пуст. Нечего очищать.")



########## КОМАНДЫ ПОЛЬЗОВАТЕЛЕЙ ЧАТА #########

#### КОМАНДА STATS ####
elif cmd == "/stats":
    user_stats = {}
    user_set = set()
    for msg in log:
        if msg["user"] != "System":
            user_stats[msg["user"]] = user_stats.get(msg["user"], 0) + 1
            user_set.add(msg["user"])
    
    total_users = len(user_set)
    total_messages = len(log)
    top_users = sorted(user_stats.items(), key=lambda x: x[1], reverse=True)

    # Подготовка строк
    log.append({"time": time.strftime("[%a,%H:%M]"), "user": "System", "text": "`!` Отчёт статистики: `!` "})
    log.append({"time": time.strftime("[%a,%H:%M]"), "user": "System", "text": f"`!` Всего сообщений: {total_messages} `!` "})
    log.append({"time": time.strftime("[%a,%H:%M]"), "user": "System", "text": f"`!` Всего пользователей: {total_users} `!` "})
    
    # Объединение топ участников в одну строку
    top_line = "`!` Топ участников: `!` " + " , ".join([f"`!` {user} ({count} сообщ.) `!`" for user, count in top_users[:5]])
    log.append({"time": time.strftime("[%a,%H:%M]"), "user": "System", "text": top_line})

############ КОМАНДА /users ##############
elif cmd == "/users":
    # Подсчёт сообщений на пользователя
    from collections import Counter
    user_counts = Counter(msg["user"] for msg in log if msg["user"] != "System")

    # Сортировка по активности
    sorted_users = sorted(user_counts.items(), key=lambda x: -x[1])
    total_users = len(sorted_users)

    # Заголовок
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": f"`!` Список активных пользователей и статистика, Всего пользователей: ({total_users}) `! "
    })

    # Показать частями по N с количеством сообщений
    for i in range(0, total_users, 7):
        chunk = ", ".join(f"`!` {user} `!({count}сообщ.)" for user, count in sorted_users[i:i+7])
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": chunk
        })

############# СТРОКИ ИНФОРМАЦИИ КОМАНДЫ /cmd ############
elif cmd == "/cmd":
    help_lines = [
        f"`!{message_icon} THE CHATROOM!{message_icon}  \\  РАСШИРЕННАЯ ИНФОРМАЦИЯ О КОМАНДАХ ПОЛЬЗОВАТЕЛЯ:`!",
        f"`!ОБЩИЕ И ИНФОРМАЦИОННЫЕ КОМАНДЫ:`!",
        f"`!/info`! :  Показать информацию о The Chat Room!, использование и отказ",
        f"`!/cmd`! : Показать все доступные команды пользователя",
        f"`!/stats`! : Показать статистику чата, включая Топ-5 участников",
        f"`!/users`! : Список всех пользователей чата",
        f"`!/version`! : Показать версию скрипта THE CHAT ROOM!, новости и информацию",

        f"`! {cmd_icon} ИНТЕРАКТИВНЫЕ КОМАНДЫ ЧАТА`!",
        "`!/lastseen <username>`!`: Информация о последнем появлении пользователя и последнее сообщение пользователя",
        "`!/topic`!` : Показать или изменить тему комнаты, использование: '/topic' или '/topic Ваша новая тема здесь' ",
        "`!/search <keyword(s)>`!` : Поиск ключевых слов в полном логе чата ",
        "`!/time`!` : Показать текущее время сервера чата (UTC)",
        "`!/ping`!` : Ответить PONG! если система чата работает",
        "`!/meteo <cityname>`! : Получить информацию о погоде для вашего города, пример: /meteo Москва",
        "--------------------------------------",
        f"`! {cmd_icon} КОМАНДЫ СОЦИАЛЬНОГО ВЗАИМОДЕЙСТВИЯ`!",
        "`!` /e`!` : Отправляет случайные эмодзи из внутреннего списка эмодзи",
        "`!` /c <текстовое сообщение>`!` : Отправляет цветное сообщение чата со случайными цветами фона и шрифта",
        "`!` @nickname`!` : Отправляет цветное упоминание для выделения упомянутого пользователя в ответном сообщении",
        "`!` $e`!` : Отправляет случайный эмотикон используя '$e', можно использовать в любой части сообщения. ",
        "`!` $link`!` : Выделить ваши ссылки, пример: $link d251bfd8e30540b5bd219bbbfcc3afc5:/page/index.mu ",
        "`!` /welcome`! : Отправляет приветственное сообщение. Использование: /welcome или /welcome <nickname>. ",
        f"`!` {cmd_icon} КОМАНДЫ СТАТУСА ПОЛЬЗОВАТЕЛЯ`!`",
        "`!` /hi, /bye, /brb, /lol, /exit, /quit, /away, /back, /notice `!`",
        "`!` Пример использования команд:  /hi ИЛИ /hi Привет Мир! `! (Синтаксис действителен для всех вышеперечисленных команд!)",
        "--------------------------------------",
        f"`!` {cmd_icon} ИНФОРМАЦИЯ ОБ АДМИНИСТРАТИВНЫХ КОМАНДАХ: /admincmd (Только администраторам разрешено выполнять эту команду) `!`",
        "`!` --------- КОНЕЦ СПИСКА КОМАНД: `[НАЖМИТЕ ДЛЯ ПЕРЕЗАГРУЗКИ СТРАНИЦЫ`:/page/nomadnet.mu`username]` --------- `!",

    ]
    for line in help_lines:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": line
        })

######## АДМИНИСТРАТИВНАЯ КОМАНДА /admincmd ######## 
elif cmd == "/admincmd":
    if safe_username == SYSADMIN:
        admin_lines = [
            f"`! {cmd_icon} ИНФОРМАЦИЯ ОБ АДМИНИСТРАТИВНЫХ КОМАНДАХ `!",
            "`! У вас есть доступ к ограниченным административным функциям.`!",
            "`! /clear `! : Удаляет последнее сообщение из чата и базы данных навсегда",
            "`! /clear N`! : Удаляет последние N сообщений из чата и базы данных навсегда, пример: /clear 3",
            "`! /clear user <nickname>`! : Удалить все сообщения от указанного пользователя навсегда",
            "`! /clearall  `! : Навсегда очистить весь лог чата и базу данных (Необратимо: используйте с осторожностью!)",
            "`! /backup `! : Создаёт полную резервную копию базы данных chat_log.json в той же папке скрипта чата",
            "--------------------------------------",
            "`! КОНЕЦ СПИСКА АДМИНИСТРАТИВНЫХ КОМАНД `!"
        ]
        for line in admin_lines:
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": line
            })
    else:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": "`! ОШИБКА: У вас нет разрешения на использование /admincmd. Эта команда ограничена для SYSADMIN.`!"
        })

######### АДМИНИСТРАТИВНАЯ КОМАНДА /backup ########
elif cmd == "/backup":
    if safe_username == SYSADMIN:
        try:
            # Создание имени файла резервной копии с временной меткой в той же директории
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            backup_file = os.path.join(os.path.dirname(__file__), f"chat_log_backup_{timestamp}.json")

            # Выполнение резервной копии
            import shutil
            shutil.copy(log_file, backup_file)

            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": f"`! Резервная копия успешна: {backup_file}`!"
            })
        except Exception as e:
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": f"`! ОШИБКА: Резервная копия не удалась. Причина: {str(e)}`!"
            })
    else:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": "`! ОШИБКА: У вас нет разрешения на использование /backup - Эта команда ограничена для SYSADMIN.`!"
        })


######## КОМАНДА INFO ######### (Измените информацию по вашим предпочтениям)
elif cmd == "/info":
    info_lines = [
        "`! Информация о The Chat Room v2.00 - Обзор - Использование - Команды - Отказ - README! :) `!",
        "Добро пожаловать! Это пространство предназначено для соединения людей через интерфейс в старом стиле IRC.",
        "Регистрация не требуется, установите ваш никнейм и вы готовы общаться с другими пользователями.",
        "Никнеймы случайно окрашиваются и для каждого никнейма есть постоянный цвет.",
        "Без компромиссов приватности: используйте любой никнейм. Ничего не записывается и не связывается с вашей rns идентичностью.",
        "Это работает на Nomadnet, поэтому будет видно международно. Уважайте все языки пользователей в чате.",
        "Этот чат основан на компонентах micron, sql3 db и python.",
        "Вы можете отправлять сообщения в стиле IRC и использовать различные команды для изучения чата.",
        "`!` Справочник команд `!`",
        "Просто несколько примеров:",
        "/users : показать активных пользователей и количество сообщений",
        "/lastseen <username> : проверить недавнюю активность пользователя",
        "/topic : показать или изменить тему комнаты",
        "/stats : показать статистику чата включая топ участников",
        "`!` Используйте /cmd для просмотра полного списка доступных команд. `!`",
        "`!` Технические заметки `!`",
        "Из-за ограничений micron, чат не обновляется автоматически.",
        "Чтобы увидеть новые входящие сообщения, перезагрузите страницу используя предоставленные кнопки ссылок.",
        "Особенно на Nomadnet: Перезагрузите используя предоставленную ссылку в нижней панели чтобы избежать дублирующихся сообщений!",
        "Обновление страницы используя функцию браузера meshchat удалит постоянство никнейма, поэтому используйте нашу кнопку Reload",
        "Чтобы иметь постоянство никнейма, используйте кнопку Fingerprint в Meshchat v2.+ для сохранения и восстановления (привязка lxmf).",
        "Основной чат показывает последние ~30 сообщений; используйте кнопку внизу для просмотра полного лога чата.",
        "`!` ОТКАЗ `!`",
        "Этот чат - пространство для связи, сотрудничества и уважительного взаимодействия.",
        "Грубое, оскорбительное или неуместное поведение не допускается. Сообщения могут быть удалены.",
        "Приостановка или удаление сообщений может произойти без предварительного предупреждения в серьёзных или повторяющихся случаях.",
        "`!` ПЕРЕД СВОБОДОЙ СЛОВА ИДЁТ УВАЖЕНИЕ! - ДОБРО ПОЖАЛОВАТЬ В >>THE CHAT ROOM!<< `!`"           
    ]

    for line in info_lines:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": line
        })

############ КОМАНДА TIME ###############
elif cmd == "/time":
    from datetime import datetime
    server_time = datetime.utcnow().strftime("%A, %B %d, %Y at %H:%M:%S UTC")
    time_text = f"Текущее время сервера: {server_time}"
    log.append({"time": time.strftime("[%a,%H:%M]"), "user": "System", "text": time_text})

########## VERSION COMMAND #########  EDIT FOR YOUR LOCAL SETTINGS!
elif cmd == "/version":
    version_messages = [
        "The Chat Room v2.00 / Powered by Reticulum NomadNet / IRC Style / Nomadnet & Meshchat Compatible / Made by F",
        "This chat is running on a VPS server, powered by RNS v1.0.0 and Nomadnet v.0.8.0.",
        "Latest Implementations in v1.3b: AntiSpam Filter and Nickname persistency (Thanks To: Thomas!!)",
        "Latest Implementations in v1.4b: Improved UI with Message splitting on long messages",
        "Latest Implementations in v1.44b: Improved UI, resolved few UI bugs, added Menu Bar on the bottom, added /search command, added 'Read Last 100 Messages', started implementing user settings (for future user preferences: custom nickname colors, multiple chat themes and more...coming soon!)",
        "Latest Implementations in v1.45b:",
        "Added Social Interactions Commands, for full command list: /cmd",
        "Improved UI and readability, fixed dysplay limit function!",
        "Latest Implementations in v1.45a:",
        "Alpha Stable Version Release Ready - Improved display limit function",
        "Added SYSADMIN commands (type /admincmd for help, only allowed for SYSADMIN) ",
        "Improved AntiSpam Filters, Better UI Timestamp, Added /meteo command",
        "The ChatRoom v2.00 improvements:",
        "Code Cleaning , Nomadnet and Meshchat supported, new intro page, timestamp mod, overall script and page improvements",
        "`! Get The ChatRoom at: https://github.com/fr33n0w/thechatroom `!"
    ]

    for msg in version_messages:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": msg
        })


######## КОМАНДА LASTSEEN ########
elif cmd.startswith("/lastseen "):
    target_user = cmd[10:].strip()
    last = next((msg for msg in reversed(log) if msg["user"] == target_user), None)
    seen_text = f"Последний раз видели {target_user} в {last['time']}: {last['text']}" if last else f"Нет записей о пользователе '{target_user}'."
    log.append({"time": time.strftime("[%a,%H:%M]"), "user": "System", "text": seen_text})

######## КОМАНДА TOPIC ######## 
elif cmd.startswith("/topic "):
    new_topic = message[7:].replace("`", "").strip()
    if new_topic:
        trimmed_topic = new_topic[:70]  # ограничение до N символов
        timestamp = time.strftime("%d %B %Y")
        topic_data = {"text": trimmed_topic, "user": safe_username, "time": timestamp}
        try:
            with open(topic_file, "w") as tf:
                json.dump(topic_data, tf)
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": f"Тема установлена {safe_username} {timestamp}: {trimmed_topic} , Перезагрузите страницу!"
            })
        except Exception as e:
            debug.append(f"Ошибка обновления темы: {e}")
    else:
        debug.append("Текст темы не предоставлен.")

elif cmd == "/topic":
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": f"Текущая тема: {topic_text} (установлена {topic_author} {topic_data.get('time')})"
    })

######## КОМАНДА SEARCH ######## 
elif cmd.startswith("/search"):
    search_input = message[8:].strip().lower()

    if not search_input:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": "`!` Ошибка! Использование команды: /search <ключевые слова> - Пожалуйста, укажите одно или несколько ключевых слов! `!`"
        })
    else:
        keywords = search_input.split()
        matches = []

        for msg in log:
            if msg.get("user") == "System":
                continue
            text = msg.get("text", "").lower()
            if all(kw in text for kw in keywords):
                matches.append(msg)

        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Результаты поиска для: '{search_input}' - найдено совпадений: {len(matches)}. `!`"
        })

        for match in matches[:10]:
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": f"[{match.get('time', '??')}] <{match.get('user', '??')}> {match.get('text', '')}"
            })

        if len(matches) > 10:
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": "`!` Показаны первые 10 результатов. Уточните поиск для более конкретных совпадений. `!`"
            })

######## КОМАНДА PING ######## 
elif cmd == "/ping":
    log.append({
        "time": time.strftime("[%a,%H:%M]"),
        "user": "System",
        "text": "PONG! (Система работает!)"
    })

#########  /e RANDOM EMOJIS COMMAND ######## 
elif cmd == "/e":
    try:
        with open(EMO_DB, "r", encoding="utf-8") as f:
            emojis = [line.strip() for line in f if line.strip()]
        
        if emojis and safe_username:
            import random
            chosen = random.choice(emojis)

            # Treat emoji as a normal message
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": safe_username,
                "text": chosen
            })

            try:
                with open(log_file, "w") as f:
                    json.dump(log, f)
                debug.append(f" Emoji by '{safe_username}' sent: {chosen}")
            except Exception as e:
                debug.append(f" Emoji send error: {e}")
        else:
            log.append({
                "time": time.strftime("[%a,%H:%M]"),
                "user": "System",
                "text": "`!` Emoji list is empty or username missing. `!`"
            })
            debug.append(" Emoji command skipped: missing emoji or username.")
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Error loading emojis: {e} `!`"
        })
        debug.append(f" Emoji command error: {e}")

######## ##### COLOR /c COMMAND ######## ######
elif cmd.startswith("/c "):
    user_message = message[3:].strip().replace("`", "")  # Remove backticks to avoid formatting issues

    if user_message and safe_username:
        import random, json

        def hex_brightness(hex_code):
            r = int(hex_code[0], 16)
            g = int(hex_code[1], 16)
            b = int(hex_code[2], 16)
            return (r + g + b) / 3

        # Generate random hex color for background
        bg_raw = ''.join(random.choices("0123456789ABCDEF", k=3))
        bg_color = f"B{bg_raw}"

        # Calculate brightness
        brightness = hex_brightness(bg_raw)
        font_color = "F000" if brightness > 7.5 else "FFF"

        # Split message into chunks of 80 characters
        def split_and_colorize(text, chunk_size=80):
            chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
            return '\n'.join([f"`{bg_color}`{font_color}` {chunk} `b`f" for chunk in chunks])

        colorful_text = split_and_colorize(user_message)

        # Create log entry
        entry = {
            "time": time.strftime("[%a,%H:%M]"),
            "user": safe_username,
            "text": colorful_text
        }

        log.append(entry)

        # Write to JSON file
        try:
            with open(log_file, "w", encoding="utf-8") as f:
                json.dump(log, f)
            debug.append(f"Test: Colored Message succesfully sent! by '{safe_username}'")
        except Exception as e:
            debug.append(f"Error sending colored message: {e}")
    else:
        debug.append("Error: Color command skipped due to missing message or username.")

###### КОМАНДА /HI #######
elif cmd.startswith("/hi"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Получить цветовой код для никнейма
        nickname_color = get_color(safe_username)
        # Форматировать никнейм используя ваш стиль разметки
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Построить сообщение
        base_text = f"{colored_nickname} присоединился к Чату!"
        if user_message:
            full_text = f" `!{base_text} Сообщение: {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /hi: {e} `!`"
        })

###### /BYE COMMAND #######
elif cmd.startswith("/bye"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} покидает Чат!"
        if user_message:
            full_text = f" `!{base_text} Сообщение: {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /bye: {e} `!`"
        })

###### /quit COMMAND #######
elif cmd.startswith("/quit"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} вышел из Чата!"
        if user_message:
            full_text = f" `!{base_text} Сообщение: {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /quit: {e} `!`"
        })

###### /exit COMMAND #######
elif cmd.startswith("/exit"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} покинул Чат!"
        if user_message:
            full_text = f" `!{base_text} Сообщение: {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /exit: {e} `!`"
        })

###### /BRB COMMAND #######
elif cmd.startswith("/brb"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} покинул Чат! СКОРО ВЕРНУСЬ! BRB!"
        if user_message:
            full_text = f" `!{base_text} Сообщение: {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /brb: {e} `!`"
        })

###### /lol COMMAND #######
elif cmd.startswith("/lol"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} громко смеётся! LOL! :D "
        if user_message:
            full_text = f" `!{base_text} Сообщение: {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /lol: {e} `!`"
        })

###### /away COMMAND #######
elif cmd.startswith("/away"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} отсутствует."
        if user_message:
            full_text = f" `!{base_text} (Статус: {user_message}) `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /away: {e} `!`"
        })

###### /back COMMAND #######
elif cmd.startswith("/back"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} вернулся! "
        if user_message:
            full_text = f" `!{base_text} {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /back: {e} `!`"
        })


###### /welcome COMMAND #######
elif cmd.startswith("/welcome"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"{colored_nickname} приветствует "
        if user_message:
            full_text = f" `!{base_text} {user_message} `!"
        else:
            full_text = f" `!{base_text} всех! `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /welcome: {e} `!`"
        })

###### /notice COMMAND #######
elif cmd.startswith("/notice"):
    try:
        parts = cmd.split(" ", 1)
        user_message = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")
        # Get color code for nickname
        nickname_color = get_color(safe_username)
        # Format nickname using your markup style
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        # Build message
        base_text = f"УВЕДОМЛЕНИЕ ОТ {colored_nickname}:"
        if user_message:
            full_text = f" `!{base_text}  {user_message} `!"
        else:
            full_text = f" `!{base_text} `!"
        log.append({
            "time": timestamp,
            "user": "System",
            "text": full_text
        })
        with open(log_file, "w") as f:
            json.dump(log, f)
    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"`!` Ошибка обработки команды /notice: {e} `!`"
        })

####### КОМАНДА METEO #######
elif cmd.startswith("/meteo"):
    try:
        from geopy.geocoders import Nominatim
        import requests

        # Извлечение названия города
        parts = cmd.split(" ", 1)
        city_name = parts[1].strip() if len(parts) > 1 else ""
        timestamp = time.strftime("[%a,%H:%M]")

        if not city_name:
            raise ValueError("Название города не указано. Пример: /meteo Москва")

        # Геолокация
        geolocator = Nominatim(user_agent="weather_bot")
        location = geolocator.geocode(city_name)
        if not location:
            raise ValueError(f"Не удалось найти местоположение для '{city_name}'.")

        lat, lon = location.latitude, location.longitude

        # Вызов API Open-Meteo
        weather_url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"
        response = requests.get(weather_url)
        data = response.json()

        if "current_weather" not in data:
            raise ValueError("Данные о погоде недоступны.")

        temp = data["current_weather"]["temperature"]
        code = data["current_weather"]["weathercode"]

        # Сопоставление кодов погоды (без эмодзи)
        weather_codes = {
            0: "Ясное небо",
            1: "В основном ясно",
            2: "Переменная облачность",
            3: "Пасмурно",
            45: "Туман",
            48: "Изморозь",
            51: "Слабый моросящий дождь",
            53: "Умеренный моросящий дождь",
            55: "Сильный моросящий дождь",
            56: "Слабый ледяной дождь",
            57: "Сильный ледяной дождь",
            61: "Слабый дождь",
            63: "Умеренный дождь",
            65: "Сильный дождь",
            66: "Слабый ледяной дождь",
            67: "Сильный ледяной дождь",
            71: "Слабый снег",
            73: "Умеренный снег",
            75: "Сильный снег",
            77: "Снежная крупа",
            80: "Слабые ливни",
            81: "Умеренные ливни",
            82: "Сильные ливни",
            85: "Слабые снежные ливни",
            86: "Сильные снежные ливни",
            95: "Гроза",
            96: "Гроза со слабым градом",
            99: "Гроза с сильным градом"
        }

        description = weather_codes.get(code, "Неизвестная погода")

        # Форматирование никнейма
        nickname_color = get_color(safe_username)
        colored_nickname = f"`{nickname_color}{safe_username}`b"
        weather_text = f"Погода в {city_name}: {temp}°C, {description}"

        full_text = f"Запрос погоды от {colored_nickname}: {weather_text} "
        log.append({
            "time": timestamp,
            "user": "Meteo",
            "text": full_text
        })

        with open(log_file, "w") as f:
            json.dump(log, f)

    except Exception as e:
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"Ошибка обработки команды /meteo: {e} "
        })


##################### END OF COMMANDS, CONTINUE SCRIPT ##############################

elif raw_username and message and message.lower() != "null":
    sanitized_message = message.replace("`", "").replace("[", "")  # remove backticks and [ to prevent formatting issues

######### Spam detection logic ######## 
# banned_words = ["buy now", "free money", "click here", "subscribe", "win big", "limited offer", "act now"] , 
# edit your spam filters on top of the script

    trigger_word = next((pattern for pattern in spam_patterns if re.search(pattern, sanitized_message.lower())), None)
    is_spam = trigger_word is not None

    if is_spam:
        # Don't write to JSON, just log the system message
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": "System",
            "text": f"Обнаружен спам! Сообщение заблокировано! Сработало на: '{trigger_word}'"
        })
        debug.append(f" Спам заблокирован от '{safe_username}'")
    else:
        # Обычный поток сообщений
        log.append({
            "time": time.strftime("[%a,%H:%M]"),
            "user": safe_username,
            "text": sanitized_message
        })
        try:
            with open(log_file, "w") as f:
                json.dump(log, f)
            debug.append(f" Сообщение от '{safe_username}' отправлено!")
        except Exception as e:
            debug.append(f" Ошибка отправки: {e}")
else:
    debug.append(" Страница перезагружена. Простой. Пустое сообщение. Ожидание взаимодействия пользователя. Для расширенной информации о командах введите: /help")




#########  Вспомогательная функция для разбиения длинных сообщений используя MAX CHARS ######## 
def split_message(text, max_chars):
    words = text.split()
    lines = []
    current_line = ""
    for word in words:
        if len(current_line) + len(word) + 1 <= max_chars:
            current_line += (" " if current_line else "") + word
        else:
            lines.append(current_line)
            current_line = word
    if current_line:
        lines.append(current_line)
    return lines

#########  динамическая адаптация отображаемых сообщений интерфейса ######## 
def calculate_effective_limit(log, max_lines, max_chars):
    total_lines = 0
    effective_limit = 0

    for msg in reversed(log):
        lines = len(split_message(msg["text"], max_chars))
        if total_lines + lines > max_lines:
            break
        total_lines += lines
        effective_limit += 1

    return max(effective_limit, 1), total_lines

effective_limit, total_lines = calculate_effective_limit(log, MAX_LINES, MAX_CHARS)


########## Динамическое преобразование времени сервера UTC в локальное время ########## 
from datetime import datetime

def convert_log_time_to_local(log_time_str):
    # Парсинг времени лога - обработка форматов [HH:MM] и [Day,HH:MM]
    log_time_str = log_time_str.strip("[]")
    
    # Проверка наличия префикса дня недели (с пробелом или без после запятой)
    if "," in log_time_str:
        # Новый формат временной метки: [Tue,14:23] или [Tue, 14:23]
        parts = log_time_str.split(",")
        day_part = parts[0].strip()
        time_part = parts[1].strip()
    else:
        # Старый формат: [14:23]
        time_part = log_time_str
        day_part = None
    
    # Получить сегодняшнюю дату
    today = datetime.utcnow().date()
    
    # Парсинг как UTC
    utc_dt = datetime.strptime(f"{today} {time_part}", "%Y-%m-%d %H:%M")
    
    # Получить локальное время системы с учётом часового пояса
    local_now = datetime.now().astimezone()
    
    # Заменить tzinfo utc_dt на UTC, затем преобразовать в локальный часовой пояс
    utc_dt = utc_dt.replace(tzinfo=local_now.tzinfo)
    local_dt = utc_dt.astimezone()
    
    return local_dt.strftime("%a,%H:%M")

#########  логика определения упоминаний пользователей в сообщениях @user ######## 
def highlight_mentions_in_line(line, known_users):
    def replacer(match):
        nickname = match.group(1)
        if nickname in known_users:
            color = get_color(nickname)
            return f"`!@`{color}{nickname}`b`!"
        else:
            return f"@{nickname}"  # Оставить без цвета
    return re.sub(r"@(\w+)", replacer, line)

######## $E ДЛЯ ЭМОТИКОНОВ ######## 
with open(EMO_DB, "r", encoding="utf-8") as f:
    EMOTICONS = []
    for line in f:
        EMOTICONS.extend(line.strip().split())
# Перехват $e для эмотиконов в сообщениях
def substitute_emoticons_in_line(line):
    return re.sub(r"\$e", lambda _: random.choice(EMOTICONS), line)

######## УПОМИНАНИЯ ССЫЛОК ######
def format_links_in_line(line):
    def replacer(match):
        link = match.group(1)
        return f"`*`_`Fb9f`[{link}]`_`*`f` "
    
    # Сопоставление `$link` за которым следует пробел и затем фактическая ссылка
    return re.sub(r"\$link\s+([^\s]+)", replacer, line)

############################## Output UI template: ######################################

# Build set of known usernames
known_users = {msg["user"] for msg in log}


# sanitize and read name from display_name os env
safe_display_name = display_name.replace("`", "'")


# ОТОБРАЖЕНИЕ ИНТЕРФЕЙСА:

# Простой шаблон для совместимости с NomadNet
template = "---\n"
template += f">`!{message_icon}  THE CHAT ROOM! {message_icon}  `F007` Работает на Reticulum NomadNet - IRC стиль - Бесплатный глобальный чат - Оптимизировано для NomadNet - v2.00 `f`!\n"
template += "---\n"
template += f"`c`B000`Ff2e`!####### Тема комнаты: {topic_text} `! (Установлена: {topic_author}, {topic_data.get('time')}) `! `!`f`b`a\n"
template += "---\n"

# Простое отображение чата со всеми подстановками
for msg in log[-DISPLAY_LIMIT:]:
    message_lines = split_message(msg["text"], MAX_CHARS)
    color = get_color(msg["user"])
    
    for i, line in enumerate(message_lines):
        # Применение подстановок для сообщений не от System
        if msg["user"] != "System":
            line = substitute_emoticons_in_line(line)  # Замена $e
            line = highlight_mentions_in_line(line, known_users)  # Выделение @упоминаний
            line = format_links_in_line(line)  # Форматирование $link
        
        if i == 0:
            # Первая строка с временной меткой и пользователем
            template += f"\\{msg['time']} `{color}`!<{msg['user']}>`!`f`b {line}\n"
        else:
            # Продолжающие строки
            template += f"\\{msg['time']} `{color}`!<{msg['user']}>`!`f`b {line}\n"


template += "---\n"
template += f"`B317 {user_icon} Никнейм: `Baac`F000`<20|username`{safe_display_name}>`b`f `B317`_`[{nickset_icon} (Установить/Обновить)`:/page/nomadnet.mu`username]`_`  {message_icon} Сообщение: `Baac`F000`<87|message`>`b`f `B317`_`[{send_icon} Отправить сообщение`:/page/nomadnet.mu`username|message]`_` - `_`[Перезагрузить страницу`:/page/nomadnet.mu`username]`_`\n"
template += "---\n"
template += f"`B216`Fddd` {cmd_icon} Команды пользователя: /info, /stats, /users, /version, /lastseen, /topic, /search, /time, /ping, /meteo, /hi, /bye, /brb, /lol, /quit, /away,     ...Для полного списка команд введите: /cmd `b`f\n"
template += f"`B317`Feee` `!` {message_icon}  Всего сообщений: ({len(log)}) | {message_icon}  Сообщений на экране: ({total_lines}) | {totmsg_icon}  `[Прочитать последние 100`:/page/last100.mu]`  |  {totmsg_icon}  `[Прочитать полный лог чата (Медленно)`:/page/fullchat.mu]`!  | `!`[{setup_icon}  Настройки пользователя (Эта функция пока недоступна, скоро)`:/page/nomadnet.mu`username]`!`b`f"
template += "\n---\n"
template += "---"
print(template)