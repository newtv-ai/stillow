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


def study_item(**overrides):
    item = {
        "id": "study-a",
        "enabled": True,
        "kind": "lecture",
        "playbackType": "directAudio",
        "playbackUrl": "https://example.test/audio.mp3",
        "sourcePage": "https://example.test/source",
        "licenseUrl": "https://creativecommons.org/licenses/by-sa/4.0/",
        "adFree": True,
        "rightsStatus": "ccBySa",
        "tags": [
            "spoken_content",
            "study_drowsy",
            "low_stimulus",
            "low_pitch_screened",
            "role_comfort_only",
        ],
        "durationSeconds": 1800,
    }
    item.update(overrides)
    return item


class AudioScienceAuditTest(unittest.TestCase):
    def test_trial_aligned_short_music_is_warning_not_error(self):
        root = {"sciencePolicyVersion": 1, "items": [base_item()]}
        errors, warnings = audit.audit_catalog(root, Path("."))
        self.assertEqual(errors, [])
        self.assertTrue(any("long-form master" in warning for warning in warnings))

    def test_valid_breathing_pacer_is_separate_support_role(self):
        root = {
            "sciencePolicyVersion": 1,
            "items": [
                base_item(
                    id="breathing-a",
                    kind="breathingPacer",
                    tags=[
                        "quiet_mind",
                        "relax_body",
                        "breathing",
                        "low_stimulus",
                        "role_breathing_pacer",
                    ],
                    durationSeconds=1200,
                )
            ],
        }
        errors, warnings = audit.audit_catalog(root, Path("."))
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])

    def test_breathing_pacer_rejects_unrelated_sleep_goal(self):
        root = {
            "sciencePolicyVersion": 1,
            "items": [
                base_item(
                    id="breathing-a",
                    kind="breathingPacer",
                    tags=[
                        "breathing",
                        "low_stimulus",
                        "night_awake",
                        "role_breathing_pacer",
                    ],
                    durationSeconds=1200,
                )
            ],
        }
        errors, _ = audit.audit_catalog(root, Path("."))
        self.assertTrue(any("unrelated goal tags" in error for error in errors))

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

    def test_study_content_is_not_allowed_in_core_catalog(self):
        root = {
            "sciencePolicyVersion": 1,
            "items": [
                base_item(
                    id="study-in-core",
                    kind="lecture",
                    tags=["study_drowsy", "role_comfort_only"],
                    durationSeconds=1800,
                )
            ],
        }
        errors, _ = audit.audit_catalog(root, Path("."))
        self.assertTrue(any("study_drowsy content belongs" in error for error in errors))

    def test_valid_personalized_study_content_passes(self):
        errors, warnings = audit.audit_study_catalog({"items": [study_item()]})
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])

    def test_study_content_cannot_claim_core_sleep_goal(self):
        item = study_item()
        item["tags"] = [*item["tags"], "quiet_mind"]
        errors, _ = audit.audit_study_catalog({"items": [item]})
        self.assertTrue(any("must not claim core goals" in error for error in errors))

    def test_study_content_requires_reusable_rights_and_long_duration(self):
        errors, _ = audit.audit_study_catalog(
            {
                "items": [
                    study_item(
                        rightsStatus="unknown",
                        durationSeconds=300,
                    )
                ]
            }
        )
        self.assertTrue(any("reusable commercial rights" in error for error in errors))
        self.assertTrue(any("at least 15 minutes" in error for error in errors))

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
