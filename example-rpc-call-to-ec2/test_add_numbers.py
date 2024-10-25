import unittest
from client import get_sum

class TestClient(unittest.TestCase):

    def test_add_numbers(self):
        # Test the addition function through the client connected to the server
        result = get_sum(3, 7)
        self.assertEqual(result, 10)

    def test_add_with_zero(self):
        # Test with zero to ensure basic cases are covered
        result = get_sum(0, 5)
        self.assertEqual(result, 5)

    def test_negative_numbers(self):
        # Test with negative numbers
        result = get_sum(-2, -3)
        self.assertEqual(result, -5)

if __name__ == '__main__':
    unittest.main()
