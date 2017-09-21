//
//  MM_Namespaces.h
//  ios_dsa
//
//  Created by Ben Gottlieb on 1/26/13.
//
//


#ifndef ios_dsa_MM_Namespaces_h
#define ios_dsa_MM_Namespaces_h

#ifdef NAMESPACE	 //could be @"ModelM_"
	#define	 MNSS(s)			(NAMESPACE @"_" s)
	#define	 MNSS_BuiltIn(s)	 (NAMESPACE s)

	#define	MMNS_OBJECT_PROPERTY(propertyName)  - (void) set##propertyName: (id) v { [self setPrimitiveValue: v forKey: MNSS(#propertyName)]; }  - (id) propertyName { return [self primitiveValueForKey: MNSS(#propertyName)]; }
#else
	#define	 MNSS(s)	 (@"" s)
	#define	 MNSS_BuiltIn(s)	 (@"" s)

	#define	MMNS_OBJECT_PROPERTY(propertyName)  @dynamic propertyName
#endif


#endif
