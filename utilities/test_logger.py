import unittest
from logger import Logger


class testPathParser(unittest.TestCase):

    def setUp(self):
        self.logger = Logger()

    def test_logger_callback(self):
        '''
        Test the status callback of logger.
        '''
        test_message = 'TEST MESSAGE'
        self.logger.log(test_message, self.mock_callback)
        print 'cb result', self.callback_message
        self.assertEqual(test_message, self.callback_message)

    def mock_callback(self, message):
        self.callback_message = message

if __name__ == '__main__':
    unittest.main()
