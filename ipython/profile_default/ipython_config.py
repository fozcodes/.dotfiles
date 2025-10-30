c = get_config()
c.InteractiveShellApp.extensions.append('autoreload')
c.InteractiveShellApp.exec_lines = ['%autoreload 2']

try:
    import pandas as pd

    pd.set_option('display.max_rows', 100)
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', 1000)
except ImportError:
    pass

