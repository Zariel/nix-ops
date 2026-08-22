use dbus::blocking::{stdintf::org_freedesktop_dbus::Properties, Connection};
use dbus::message::MatchRule;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};
use std::time::Duration;

const SERVICE: &str = "com.feralinteractive.GameMode";
const ROOT: &str = "/com/feralinteractive/GameMode";
const ROOT_INTERFACE: &str = "com.feralinteractive.GameMode";
const GAME_INTERFACE: &str = "com.feralinteractive.GameMode.Game";
const TIMEOUT: Duration = Duration::from_secs(1);
const PROCESS_TIMEOUT: Duration = Duration::from_secs(60 * 60);

#[derive(Debug, Eq, Ord, PartialEq, PartialOrd)]
struct Client {
    executable: String,
    name: String,
    pid: i32,
}

fn main() {
    if let Err(error) = run() {
        emit(
            "",
            &format!("GameMode status unavailable\n{error}"),
            "error",
        );
    }
}

fn run() -> Result<(), String> {
    let connection = Connection::new_session()
        .map_err(|error| format!("could not connect to the session bus: {error}"))?;
    let changed = Arc::new(AtomicBool::new(false));

    watch(&connection, "GameRegistered", Arc::clone(&changed))?;
    watch(&connection, "GameUnregistered", Arc::clone(&changed))?;
    refresh(&connection);

    loop {
        connection
            .process(PROCESS_TIMEOUT)
            .map_err(|error| format!("lost the session bus connection: {error}"))?;
        if changed.swap(false, Ordering::Relaxed) {
            refresh(&connection);
        }
    }
}

fn watch(
    connection: &Connection,
    member: &'static str,
    changed: Arc<AtomicBool>,
) -> Result<(), String> {
    let mut rule = MatchRule::new_signal(ROOT_INTERFACE, member);
    rule.path = Some(ROOT.into());
    connection
        .add_match(rule, move |_: (i32, dbus::Path<'static>), _, _| {
            changed.store(true, Ordering::Relaxed);
            true
        })
        .map(|_| ())
        .map_err(|error| format!("could not subscribe to {member}: {error}"))
}

fn refresh(connection: &Connection) {
    match clients(connection) {
        Ok(clients) => render(&clients),
        Err(error) => emit(
            "",
            &format!("GameMode status unavailable\n{error}"),
            "error",
        ),
    }
}

fn clients(connection: &Connection) -> Result<Vec<Client>, String> {
    let proxy = connection.with_proxy(SERVICE, ROOT, TIMEOUT);
    let (games,): (Vec<(i32, dbus::Path<'static>)>,) = proxy
        .method_call(ROOT_INTERFACE, "ListGames", ())
        .map_err(|error| format!("could not list GameMode clients: {error}"))?;
    let mut clients = Vec::new();

    for (pid, object) in games {
        if !object.starts_with("/com/feralinteractive/GameMode/Games/") {
            continue;
        }

        let executable =
            property(connection, &object, "Executable").unwrap_or_else(|_| format!("PID {pid}"));
        clients.push(Client {
            name: resolve_name(pid, &executable),
            executable,
            pid,
        });
    }

    clients.sort();
    Ok(clients)
}

fn property(
    connection: &Connection,
    object: &dbus::Path<'_>,
    property: &str,
) -> Result<String, String> {
    connection
        .with_proxy(SERVICE, object, TIMEOUT)
        .get(GAME_INTERFACE, property)
        .map_err(|error| format!("could not read {property}: {error}"))
}

fn display_name(executable: &str) -> String {
    Path::new(executable)
        .file_name()
        .and_then(|name| name.to_str())
        .filter(|name| !name.is_empty())
        .unwrap_or(executable)
        .to_owned()
}

fn resolve_name(pid: i32, executable: &str) -> String {
    let Some(arguments) = process_arguments(pid) else {
        return display_name(executable);
    };

    if let (Some(app_id), Some(steamapps)) = (steam_app_id(&arguments), steamapps_path(&arguments))
    {
        let manifest = steamapps.join(format!("appmanifest_{app_id}.acf"));
        if let Ok(contents) = fs::read_to_string(manifest) {
            if let Some(name) = manifest_name(&contents) {
                return name;
            }
        }
    }

    arguments
        .iter()
        .rev()
        .find(|argument| {
            argument.contains("/steamapps/common/") && !argument.contains("/SteamLinuxRuntime")
        })
        .map(|argument| display_name(argument))
        .unwrap_or_else(|| display_name(executable))
}

fn process_arguments(pid: i32) -> Option<Vec<String>> {
    let command_line = fs::read(format!("/proc/{pid}/cmdline")).ok()?;
    Some(
        command_line
            .split(|byte| *byte == 0)
            .filter(|argument| !argument.is_empty())
            .map(|argument| String::from_utf8_lossy(argument).into_owned())
            .collect(),
    )
}

fn steam_app_id(arguments: &[String]) -> Option<&str> {
    arguments
        .iter()
        .find_map(|argument| argument.strip_prefix("AppId="))
        .filter(|app_id| {
            !app_id.is_empty() && app_id.chars().all(|character| character.is_ascii_digit())
        })
}

fn steamapps_path(arguments: &[String]) -> Option<PathBuf> {
    arguments.iter().find_map(|argument| {
        let (library, _) = argument.split_once("/steamapps/common/")?;
        Some(Path::new(library).join("steamapps"))
    })
}

fn manifest_name(manifest: &str) -> Option<String> {
    let words = parse_acf_words(manifest).ok()?;
    words
        .windows(2)
        .find(|pair| pair[0] == "name")
        .map(|pair| pair[1].clone())
}

fn render(clients: &[Client]) {
    if clients.is_empty() {
        emit("", "GameMode inactive", "inactive");
        return;
    }

    let text = if clients.len() == 1 {
        format!(" {}", shorten(&clients[0].name, 24))
    } else {
        format!(" {}", clients.len())
    };
    let mut tooltip = format!("GameMode active for {} client(s)", clients.len());
    for client in clients {
        tooltip.push_str(&format!("\n• {} (PID {})", client.name, client.pid));
        let executable = display_name(&client.executable);
        if executable != client.name {
            tooltip.push_str(&format!("\n  via {executable}"));
        }
    }
    emit(&text, &tooltip, "running");
}

fn shorten(value: &str, limit: usize) -> String {
    if value.chars().count() <= limit {
        return value.to_owned();
    }
    let mut shortened: String = value.chars().take(limit.saturating_sub(1)).collect();
    shortened.push('…');
    shortened
}

fn emit(text: &str, tooltip: &str, class: &str) {
    let mut output = io::stdout().lock();
    writeln!(
        output,
        "{{\"text\":\"{}\",\"tooltip\":\"{}\",\"class\":\"{}\"}}",
        json(text),
        json(tooltip),
        json(class)
    )
    .expect("could not write Waybar output");
    output.flush().expect("could not flush Waybar output");
}

fn json(value: &str) -> String {
    let mut escaped = String::with_capacity(value.len());
    for character in value.chars() {
        match character {
            '"' => escaped.push_str("\\\""),
            '\\' => escaped.push_str("\\\\"),
            '\n' => escaped.push_str("\\n"),
            '\r' => escaped.push_str("\\r"),
            '\t' => escaped.push_str("\\t"),
            character if character.is_control() => {
                escaped.push_str(&format!("\\u{:04x}", character as u32));
            }
            character => escaped.push(character),
        }
    }
    escaped
}

fn parse_acf_words(input: &str) -> Result<Vec<String>, String> {
    let mut words = Vec::new();
    let mut word = String::new();
    let mut characters = input.chars().peekable();
    let mut quoted = false;
    let mut active = false;

    while let Some(character) = characters.next() {
        match character {
            '"' => {
                quoted = !quoted;
                active = true;
            }
            '\\' if quoted => {
                active = true;
                let escaped = characters
                    .next()
                    .ok_or_else(|| "unfinished escape".to_owned())?;
                match escaped {
                    'n' => word.push('\n'),
                    'r' => word.push('\r'),
                    't' => word.push('\t'),
                    '"' => word.push('"'),
                    '\\' => word.push('\\'),
                    'x' => {
                        let high = characters
                            .next()
                            .ok_or_else(|| "short hexadecimal escape".to_owned())?;
                        let low = characters
                            .next()
                            .ok_or_else(|| "short hexadecimal escape".to_owned())?;
                        let value = u8::from_str_radix(&format!("{high}{low}"), 16)
                            .map_err(|_| "invalid hexadecimal escape".to_owned())?;
                        word.push(char::from(value));
                    }
                    escaped => word.push(escaped),
                }
            }
            character if character.is_whitespace() && !quoted => {
                if active {
                    words.push(std::mem::take(&mut word));
                    active = false;
                }
            }
            character => {
                active = true;
                word.push(character);
            }
        }
    }

    if quoted {
        return Err("unterminated quote".to_owned());
    }
    if active {
        words.push(word);
    }
    Ok(words)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_executable_basename() {
        assert_eq!(display_name("/games/My Game"), "My Game");
    }

    #[test]
    fn finds_steam_app() {
        let arguments = vec![
            "reaper".to_owned(),
            "SteamLaunch".to_owned(),
            "AppId=108600".to_owned(),
            "/srv/steam-library/steamapps/common/ProjectZomboid/projectzomboid.sh".to_owned(),
        ];
        assert_eq!(steam_app_id(&arguments), Some("108600"));
        assert_eq!(
            steamapps_path(&arguments),
            Some(PathBuf::from("/srv/steam-library/steamapps"))
        );
    }

    #[test]
    fn reads_manifest_name() {
        assert_eq!(
            manifest_name(r#""AppState" { "appid" "108600" "name" "Project Zomboid" }"#),
            Some("Project Zomboid".to_owned())
        );
    }

    #[test]
    fn escapes_json() {
        assert_eq!(json("one\n\"two\""), "one\\n\\\"two\\\"");
    }
}
