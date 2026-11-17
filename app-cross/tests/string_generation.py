# SPDX-FileCopyrightText: 2026 Davide De Rosa
# SPDX-License-Identifier: GPL-3.0

import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    'generator', Path(__file__).resolve().parents[1] / 'scripts/import-apple-strings.py')
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


class StringGenerationTests(unittest.TestCase):
    def test_escapes(self):
        self.assertEqual(generator.unescape(r'a\n\t\"\\\U00E9\UD83D\UDE00'), 'a\n\t"\\é😀')
        with self.assertRaises(ValueError):
            generator.unescape(r'\Uxyz')

    def test_parser(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'Localizable.strings'
            path.write_text('// comment\n/* block */ "key" = "value";', encoding='utf-8')
            self.assertEqual(generator.read_strings(path), {'key': 'value'})
            for invalid in ('"key" = "a"; "key" = "b";', '"key" = "value"', '/* unclosed'):
                path.write_text(invalid, encoding='utf-8')
                with self.assertRaises(ValueError):
                    generator.read_strings(path)

    def test_catalog_validation_and_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            english = root / 'en.lproj/Localizable.strings'
            french = root / 'fr.lproj/Localizable.strings'
            for path in (english, french):
                path.parent.mkdir()
            english.write_text('"hello.world" = "Hello"; "android.optional" = "Optional";', encoding='utf-8')
            french.write_text('"hello.world" = "Bonjour";', encoding='utf-8')
            output, keys = root / 'output/strings.inc', root / 'output/strings_keys.h'
            generator.generate(root, output, keys)
            self.assertIn('HelloWorld,', keys.read_text(encoding='utf-8'))
            self.assertIn('{"fr", "hello.world", "Bonjour"}', output.read_text(encoding='utf-8'))
            self.assertNotIn(b'\r', output.read_bytes())
            for invalid in ('', '"hello.world" = "Bonjour"; "unknown" = "x";'):
                french.write_text(invalid, encoding='utf-8')
                with self.assertRaises(ValueError):
                    generator.generate(root, output, keys)
            english.write_text('"hello.world" = "a"; "hello-world" = "b";', encoding='utf-8')
            french.write_text(english.read_text(encoding='utf-8'), encoding='utf-8')
            with self.assertRaises(ValueError):
                generator.generate(root, output, keys)


if __name__ == '__main__':
    unittest.main()
