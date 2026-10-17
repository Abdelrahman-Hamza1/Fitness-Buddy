import os
import unittest

import off_coverage as oc

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "testdata", "off-coverage")


class OffCoverageTest(unittest.TestCase):
    def setUp(self):
        with open(os.path.join(HERE, "sample.yaml"), encoding="utf-8") as f:
            self.sample = oc.parse_sample(f.read())
        with open(os.path.join(HERE, "fixture.tsv"), encoding="utf-8", newline="") as f:
            self.res = oc.analyze(f, self.sample)

    def test_counts_and_completeness(self):
        self.assertEqual(self.res["total"], 20)
        self.assertEqual(self.res["per"]["ALL"], [8, 5, 4])
        self.assertEqual(self.res["per"]["PS_or_JO"], [4, 3, 2])
        self.assertEqual(self.res["per"]["en:jordan"], [3, 2, 1])
        self.assertEqual(self.res["tags"]["en:west-bank"], 1)

    def test_prefix_split(self):
        self.assertEqual(self.res["prefixes"]["ALL"]["625"], 3)
        self.assertEqual(self.res["prefixes"]["ALL"]["729"], 2)

    def test_sample_matches(self):
        f = self.res["found"]
        self.assertEqual(f["hamm"], [1, 1, 1])
        self.assertEqual(f["tnuva"], [2, 2, 2])  # matched anywhere in OFF
        self.assertEqual(f["bamba"], [1, 0, 0])
        self.assertEqual(f["none"], [0, 0, 0])

    def test_verdict(self):
        self.assertIn("barcode first", oc.report(self.res, self.sample))  # 2 of 4 = 50%


if __name__ == "__main__":
    unittest.main()
