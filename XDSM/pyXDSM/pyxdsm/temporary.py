import os
import shutil


class Temporary(object):

    def __init__(self, file_path, directory):
        self.file_path = file_path
        self.directory = directory
        self.temp_path = []

    def __enter__(self):
        file_path = self.file_path if isinstance(self.file_path, (list, tuple)) else (self.file_path,)  # Ensure Iter.
        for path in file_path:
            base_path = os.path.basename(path)
            self.temp_path += [os.path.join(self.directory, base_path)]
            shutil.copy2(path, self.temp_path[-1])

    def __exit__(self, exc_type, exc_val, exc_traceback):
        for temp in self.temp_path:
            os.remove(temp)
