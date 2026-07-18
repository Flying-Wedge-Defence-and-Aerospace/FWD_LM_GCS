
add_library(Airspace
	AirspaceManager.cc
	AirspaceManager.h
	AirspaceZone.cc
	AirspaceZone.h
	MvtDecoder.cc
	MvtDecoder.h
)

target_link_libraries(Airspace
	PUBLIC
		qgc
)

target_include_directories(Airspace PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
