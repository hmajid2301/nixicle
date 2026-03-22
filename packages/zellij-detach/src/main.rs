use std::collections::BTreeMap;
use std::path::PathBuf;
use zellij_tile::prelude::*;

#[derive(Default)]
struct DetachPlugin;

#[cfg(target_family = "wasm")]
register_plugin!(DetachPlugin);

#[cfg(target_family = "wasm")]
impl ZellijPlugin for DetachPlugin {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::ReadCliPipes,
        ]);
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if let (PipeSource::Cli(_), Some(payload)) =
            (pipe_message.source, pipe_message.payload.as_deref())
        {
            if payload == "detach" {
                detach();
            } else if let Some(cmd) = payload.strip_prefix("switch:") {
                // Parse: "session_name:cwd:layout_path" or "session_name:cwd" or just "session_name"
                let parts: Vec<&str> = cmd.splitn(3, ':').collect();
                let session_name = parts[0];
                let cwd = if parts.len() > 1 && !parts[1].is_empty() {
                    Some(PathBuf::from(parts[1]))
                } else {
                    None
                };
                let layout_path = if parts.len() > 2 && !parts[2].is_empty() {
                    Some(parts[2])
                } else {
                    None
                };

                if let Some(layout) = layout_path {
                    let layout_info = LayoutInfo::File(layout.to_string());
                    switch_session_with_layout(Some(session_name), layout_info, cwd);
                } else {
                    switch_session_with_cwd(Some(session_name), cwd);
                }
            }
        }

        false
    }
}
