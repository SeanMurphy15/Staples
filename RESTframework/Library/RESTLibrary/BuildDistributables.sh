LIB_DESTINATION="./../RESTLibrary/RESTFrameworkLibrary"
HEADERS_FOLDER="${LIB_DESTINATION}/Headers"
RESOURCE_FOLDER="${LIB_DESTINATION}/Resources"


echo "Lipo'ing ${LIB_DESTINATION}"

mkdir -p "${HEADERS_FOLDER}"
mkdir -p "${RESOURCE_FOLDER}"

lipo -create "build/Release-iphoneos/libRESTLibrary.a" "build/Debug-iphonesimulator/libRESTLibrary.a" -output "${LIB_DESTINATION}/libRESTLibrary.a"
#lipo -create "build/Debug-iphoneos/libRESTLibrary.a" "build/Debug-iphonesimulator/libRESTLibrary.a" -output "${LIB_DESTINATION}/libRESTLibraryD.a"

SRC_HEADERS="build/Debug-iphonesimulator/usr/local/include/*.h"
for HEADER in ${SRC_HEADERS}; do
	FILENAME="${HEADER##*/}"
	cp $HEADER "${HEADERS_FOLDER}/${FILENAME}" 
done

SRC_HEADERS="../../Required/Libraries/SA_Base.framework/Headers/*.h"
for HEADER in ${SRC_HEADERS}; do
	FILENAME="${HEADER##*/}"
	cp $HEADER "${HEADERS_FOLDER}/${FILENAME}"
done

RSC_SRC_DIR="${PROJECT_DIR}/../.."

cp "${RSC_SRC_DIR}/Optional/UI/View Controllers/Web View/MM_WebViewController.xib" "${RESOURCE_FOLDER}/MM_WebViewController.xib"
mkdir -p "${RESOURCE_FOLDER}/MetaModel.xcdatamodeld/MetaModel.xcdatamodel"
cp "${RSC_SRC_DIR}/Required/Model/Meta/MetaModel.xcdatamodeld/MetaModel.xcdatamodel/contents" "${RESOURCE_FOLDER}/MetaModel.xcdatamodeld/MetaModel.xcdatamodel/contents"

echo "Library built and ready"