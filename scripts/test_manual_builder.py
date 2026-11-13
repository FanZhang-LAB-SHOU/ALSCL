"""Regression checks for bilingual manual code preservation (standard library only)."""
import unittest

from build_manual import (ARTICLE_TARGET, WEB, blocks, check_alignment,
                          code_signature, merge_code)


def block(*lines):
    return ['```r', *lines, '```']


class ManualCodeTests(unittest.TestCase):
    def assert_merge(self, en, zh):
        check_alignment('test', [('code', en)], [('code', zh)])
        merged = merge_code(en, zh)
        self.assertEqual(code_signature(en), code_signature(merged))
        return merged

    def test_shorter_chinese_comments_do_not_truncate_last_statement(self):
        en = block('# Read the data', '# Then inspect it', 'x <- 1', 'print(x)')
        zh = block('# 读取并检查', 'x <- 1', 'print(x)')
        merged = self.assert_merge(en, zh)
        self.assertIn('print(x)', merged)
        self.assertIn('# Then inspect it', merged)

    def test_shorter_english_comments_retain_chinese_explanation(self):
        en = block('# Read', 'x <- 1', 'print(x)')
        zh = block('# 读取', '# 然后检查', '', 'x <- 1', 'print(x)', '# 完成')
        merged = self.assert_merge(en, zh)
        self.assertIn('# 然后检查', merged)
        self.assertIn('# 完成', merged)

    def test_blank_lines_do_not_misalign_inline_comments(self):
        en = block('# First', '', 'x <- 1 # input', 'print(x) # output')
        zh = block('', '# 第一步', 'x <- 1 # 输入', '', '', 'print(x) # 输出')
        merged = self.assert_merge(en, zh)
        self.assertIn('x <- 1 # 输入 / input', merged)
        self.assertIn('print(x) # 输出 / output', merged)

    def test_existing_bilingual_comments_are_not_duplicated(self):
        en = block('# Model-specific settings', 'x <- 1 # input')
        zh = block('# 模型设置 / Model-specific settings', 'x <- 1 # 输入 / input')
        merged = self.assert_merge(en, zh)
        self.assertIn('# 模型设置 / Model-specific settings', merged)
        self.assertIn('x <- 1 # 输入 / input', merged)
        self.assertNotIn('/ input / input', '\n'.join(merged))

    def test_unequal_comment_groups_are_not_positionally_paired(self):
        en = block('# Model-specific settings', '# Review starts', 'x <- 1')
        zh = block('# 模型设置 / Model-specific settings',
                   '# Growth parameters are fixed', '# 检查初值', 'x <- 1')
        merged = self.assert_merge(en, zh)
        self.assertIn('# Review starts', merged)
        self.assertIn('# Growth parameters are fixed', merged)
        self.assertIn('# 模型设置 / Model-specific settings', merged)
        self.assertNotIn('Growth parameters are fixed / Review starts', '\n'.join(merged))
        self.assertEqual('\n'.join(merged).count('Model-specific settings'), 1)

    def test_hashes_in_strings_and_backticks_are_code(self):
        en = block('x <- "prefix#suffix" # English', "y <- 'abc#123'", '`a#b` <- x')
        zh = block('x <- "prefix#suffix" # 中文', "y <- 'abc#123'", '`a#b` <- x')
        self.assert_merge(en, zh)
        changed = block('x <- "prefix#DIFFERENT" # 中文', "y <- 'abc#123'", '`a#b` <- x')
        with self.assertRaises(SystemExit):
            check_alignment('test', [('code', en)], [('code', changed)])
        with self.assertRaises(ValueError):
            merge_code(en, changed)

    def test_escaped_quotes_and_raw_strings_preserve_hashes(self):
        en = block(r'x <- "a\"#b" # English', 'y <- r"-(a"#b)-" # raw')
        zh = block(r'x <- "a\"#b" # 中文', 'y <- r"-(a"#b)-" # 原始字符串')
        merged = self.assert_merge(en, zh)
        self.assertIn('y <- r"-(a"#b)-" # 原始字符串 / raw', merged)

    def test_multiline_strings_keep_comment_like_lines_and_blanks(self):
        en = block('x <- "first', '# literal text', '', 'last" # done', 'print(x)')
        zh = block('x <- "first', '# literal text', '', 'last" # 完成', '', 'print(x)')
        merged = self.assert_merge(en, zh)
        self.assertIn('# literal text', merged)
        self.assertEqual(code_signature(merged)[1][2], '')

    def test_every_current_article_keeps_its_executable_code(self):
        count = 0
        for slug in ARTICLE_TARGET:
            en = blocks((WEB / 'en' / 'articles' / (slug + '.md')).read_text(encoding='utf-8'))
            zh = blocks((WEB / 'zh' / 'articles' / (slug + '.md')).read_text(encoding='utf-8'))
            check_alignment(slug, en, zh)
            for (kind, el), (_, zl) in zip(en, zh):
                if kind == 'code':
                    with self.subTest(article=slug, block=count):
                        self.assert_merge(el, zl)
                    count += 1
        self.assertGreater(count, 100)

    def test_reference_examples_keep_hashes_inside_strings(self):
        from extract_reference_examples import website_helpers
        code_language = website_helpers()['code_language']
        line = 'plot_SSB(b, line_color = "#1B9E77") # 自定义颜色 / Custom colour'
        self.assertEqual(code_language(line, 'en'),
                         'plot_SSB(b, line_color = "#1B9E77") # Custom colour')
        self.assertEqual(code_language(line, 'zh'),
                         'plot_SSB(b, line_color = "#1B9E77") # 自定义颜色')
        # A line without a comment, and a hash in a multi-line string, stay as written.
        code = 'x <- "first\n# literal text\nlast"\nprint(x)'
        self.assertEqual(code_language(code, 'en'), code)

    def test_reference_examples_keep_a_space_after_the_hash(self):
        from extract_reference_examples import reference_examples
        for entry in reference_examples(['plot_compare_growth', 'diagnostic_metrics']):
            for line in entry['example'].splitlines():
                if line.lstrip().startswith('#'):
                    self.assertRegex(line.lstrip(), r'^#( |$)')
            if entry['language'] == 'en':
                self.assertNotRegex(entry['example'], '[\u3400-\u9fff]')

    def test_math_is_retained_verbatim(self):
        en = ['```math', 'a # b', '', 'c', '```']
        self.assertEqual(merge_code(en, en), en)


if __name__ == '__main__':
    unittest.main(verbosity=2)
