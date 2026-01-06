use super::{PrivacyMode, PrivacyModeState, ResultType, INVALID_PRIVACY_MODE_CONN_ID};

pub const PRIVACY_MODE_IMPL: &str = "privacy_mode_impl_android";

pub struct PrivacyModeImpl {
    conn_id: i32,
    impl_key: String,
}

impl PrivacyModeImpl {
    pub fn new(impl_key: &str) -> Self {
        Self {
            conn_id: INVALID_PRIVACY_MODE_CONN_ID,
            impl_key: impl_key.to_owned(),
        }
    }
}

impl PrivacyMode for PrivacyModeImpl {
    fn is_async_privacy_mode(&self) -> bool {
        false
    }

    fn init(&self) -> ResultType<()> {
        Ok(())
    }

    fn clear(&mut self) {
        self.conn_id = INVALID_PRIVACY_MODE_CONN_ID;
    }

    fn turn_on_privacy(&mut self, conn_id: i32) -> ResultType<bool> {
        self.conn_id = conn_id;
        // Notify Flutter/Android frontend
        let data = serde_json::json!({
            "name": "privacy_mode_state",
            "on": true
        });
        crate::flutter::push_global_event(crate::flutter::APP_TYPE_MAIN, data.to_string());
        Ok(true)
    }

    fn turn_off_privacy(&mut self, _conn_id: i32, _state: Option<PrivacyModeState>) -> ResultType<()> {
        self.conn_id = INVALID_PRIVACY_MODE_CONN_ID;
        // Notify Flutter/Android frontend
        let data = serde_json::json!({
            "name": "privacy_mode_state",
            "on": false
        });
        crate::flutter::push_global_event(crate::flutter::APP_TYPE_MAIN, data.to_string());
        Ok(())
    }

    fn pre_conn_id(&self) -> i32 {
        self.conn_id
    }

    fn get_impl_key(&self) -> &str {
        &self.impl_key
    }
}
