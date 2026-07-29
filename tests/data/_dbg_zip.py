import zipfile, sys
with zipfile.ZipFile(sys.argv[1], 'w') as z:
    z.writestr('manifest.json', 'test')
    z.writestr('content.pck', 'test')
