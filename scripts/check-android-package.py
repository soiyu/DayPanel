"""Read-only release artifact checks. No signing or publishing."""
import pathlib, struct, sys, zipfile
p=pathlib.Path(sys.argv[1])
failures=[];count=0
with zipfile.ZipFile(p) as z:
 for name in z.namelist():
  if not (name.endswith('.so') and ('arm64-v8a/' in name or 'x86_64/' in name)):continue
  data=z.read(name);count+=1
  if data[:4]!=b'\x7fELF' or data[4]!=2:failures.append(name+': not ELF64');continue
  order='<' if data[5]==1 else '>'
  off=struct.unpack_from(order+'Q',data,32)[0];size,num=struct.unpack_from(order+'HH',data,54)
  for i in range(num):
   kind,flags,offset,vaddr,paddr,filesz,memsz,align=struct.unpack_from(order+'IIQQQQQQ',data,off+i*size)
   if kind==1 and (align<16384 or vaddr%16384!=offset%16384):failures.append(name+': PT_LOAD not 16KB compatible')
print('64-bit native libraries inspected:',count)
if not count:failures.append('No 64-bit libraries found')
if failures:print('\n'.join(failures));sys.exit(1)
print('PASS: inspected ELF load segments meet 16KB alignment. Device installation and runtime testing remain required.')
