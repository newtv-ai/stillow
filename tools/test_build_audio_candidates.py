import importlib.util
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).with_name("build_audio_candidates.py")
SPEC = importlib.util.spec_from_file_location("build_audio_candidates", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AudioCandidateBuilderTest(unittest.TestCase):
    def test_license_filter_accepts_reusable_rights(self) -> None:
        self.assertEqual(
            MODULE._classify_license("CC BY-SA 4.0", "https://creativecommons.org/licenses/by-sa/4.0/"),
            ("ccBySa", "CC BY-SA 4.0"),
        )
        self.assertEqual(
            MODULE._classify_license("CC0 1.0", "https://creativecommons.org/publicdomain/zero/1.0/"),
            ("cc0", "CC0"),
        )

    def test_license_filter_rejects_noncommercial_and_no_derivatives(self) -> None:
        self.assertIsNone(
            MODULE._classify_license("CC BY-NC 4.0", "https://creativecommons.org/licenses/by-nc/4.0/")
        )
        self.assertIsNone(
            MODULE._classify_license("CC BY-ND 4.0", "https://creativecommons.org/licenses/by-nd/4.0/")
        )

    def test_missing_public_domain_license_url_gets_canonical_link(self) -> None:
        self.assertEqual(
            MODULE._license_url_or_default(
                "publicDomain", "", "Public Domain"
            ),
            "https://creativecommons.org/publicdomain/mark/1.0/",
        )

    def test_open_game_art_parser_prefers_original_files_and_reads_size(self) -> None:
        page = """
        <div data-mp3-url='https://example.test/audio_preview/calm.mp3'></div>
        <a href='https://example.test/calm.ogg' type='audio/ogg; length=1234'>calm.ogg</a>
        <a href='https://example.test/calm.mp3' type='audio/mpeg; length=5678'>calm.mp3</a>
        """
        self.assertEqual(
            MODULE._oga_original_files(page),
            [
                ("https://example.test/calm.ogg", 1234),
                ("https://example.test/calm.mp3", 5678),
            ],
        )

    def test_spoken_title_filter_removes_distressing_and_low_signal_topics(self) -> None:
        self.assertTrue(MODULE._reject_spoken_title("阿道夫·希特勒之死"))
        self.assertTrue(MODULE._reject_spoken_title("Part1"))
        self.assertTrue(MODULE._reject_spoken_title("Dongping dialect-接山镇"))
        self.assertFalse(MODULE._reject_spoken_title("奥拉基库克山国家公园"))
        self.assertFalse(MODULE._reject_spoken_title("路德维希·范·贝多芬-part 2"))

    def test_balanced_selection_keeps_both_content_types(self) -> None:
        spoken = [
            {
                "id": f"spoken-{index}",
                "kind": "spokenKnowledge",
                "selectionScore": 90 - index,
                "durationSeconds": 600,
                "title": f"Spoken {index}",
            }
            for index in range(20)
        ]
        music = [
            {
                "id": f"music-{index}",
                "kind": "music",
                "selectionScore": 90 - index,
                "durationSeconds": None,
                "title": f"Music {index}",
            }
            for index in range(20)
        ]
        selected = MODULE.select_balanced(spoken + music, 20)
        self.assertEqual(len(selected), 20)
        self.assertEqual(sum(item["kind"] == "music" for item in selected), 7)
        self.assertEqual(sum(item["kind"] == "spokenKnowledge" for item in selected), 13)

    def test_archive_filter_requires_calm_title_and_reusable_license(self) -> None:
        base = {
            "licenseurl": "https://creativecommons.org/publicdomain/zero/1.0/",
            "subject": ["field recording", "nature"],
            "description": "steady recording",
        }
        self.assertTrue(
            MODULE._archive_document_is_relevant(
                {**base, "title": "Nature Sounds - Gentle Rain"}
            )
        )
        self.assertFalse(
            MODULE._archive_document_is_relevant(
                {**base, "title": "Alec Bridges Live at Ocean Avenue"}
            )
        )
        self.assertFalse(
            MODULE._archive_document_is_relevant(
                {
                    **base,
                    "title": "Rain Sounds",
                    "licenseurl": "https://creativecommons.org/licenses/by-nc/4.0/",
                }
            )
        )

    def test_duration_parser_handles_seconds_and_clock_values(self) -> None:
        self.assertEqual(MODULE._parse_duration("900.4"), 900)
        self.assertEqual(MODULE._parse_duration("12:30"), 750)
        self.assertEqual(MODULE._parse_duration("1:02:03"), 3723)


if __name__ == "__main__":
    unittest.main()
