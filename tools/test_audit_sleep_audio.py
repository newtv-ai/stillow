import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("audit_sleep_audio.py")
SPEC = importlib.util.spec_from_file_location("audit_sleep_audio", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)


def base_item(**overrides):
    item = {
        "id": "music-a",
        "enabled": False,
        "kind": "music",
        "playbackType": "metadataOnly",
        "tags": [
            "quiet_mind",
            "music",
            "ambient",
            "low_stimulus",
            "instrumental",
            "role_trial_aligned_music",
            "needs_long_form_master",
        ],
        "durationSeconds": 180,
    }
    item.update(overrides)
    return item


class AudioScienceAuditTest(unittest.TestCase):
    def test_trial_aligned_short_music_is_warning_not_error(self):
        root = {"sciencePolicyVersion": 1, "items": [base_item()]}
        errors, warnings = audit.audit_catalog(root, Path("."))
        self.assertEqual(errors, [])
        self.assertTrue(any("long-form master" in warning for warning in warnings))

    def test_masking_cannot_claim_quiet_mind(self):
        root = {
            "sciencePolicyVersion": 1,
            "items": [
                base_item(
                    id="rain-a",
                    kind="rain",
                    tags=["mask_noise", "quiet_mind", "role_masking_only"],
                    durationSeconds=300,
                )
            ],
        }
        errors, _ = audit.audit_catalog(root, Path("."))
        self.assertTrue(any("non-masking goal tags" in error for error in errors))

    def test_comfort_only_cannot_claim_night_awake(self):
        root = {
            "sciencePolicyVersion": 1,
            "items": [
                base_item(
                    id="spoken-a",
                    kind="narrative",
                    tags=["gentle_company", "night_awake", "role_comfort_only"],
                    durationSeconds=1200,
                )
            ],
        }
        errors, _ = audit.audit_catalog(root, Path("."))
        self.assertTrue(any("core goal tags" in error for error in errors))

    def test_bundled_sha_is_verified(self):
        with tempfile.TemporaryDirectory() as tmp:
            root_dir = Path(tmp)
            audio = root_dir / "assets" / "audio" / "x.mp3"
            audio.parent.mkdir(parents=True)
            audio.write_bytes(b"known audio bytes")
            item = base_item(
                id="asset-a",
                enabled=True,
                playbackType="assetAudio",
                assetPath="assets/audio/x.mp3",
                sha256="0" * 64,
            )
            root = {"sciencePolicyVersion": 1, "items": [item]}
            errors, _ = audit.audit_catalog(root, root_dir)
            self.assertTrue(any("sha256 mismatch" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
