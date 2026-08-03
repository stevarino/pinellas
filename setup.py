import os

paths = ['csvs', 'shapes']

def main():
  for path in paths:
    try:
      os.mkdir(path)
    except OSError as e:
      print(e)    
  
if __name__ == '__main__':
  main()