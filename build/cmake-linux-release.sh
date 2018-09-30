rm -rf unix
mkdir unix
cd unix
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DONATIVE=ON ../../src
