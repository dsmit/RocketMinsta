typedef float(string s, vector size) textLengthUpToWidth_widthFunction_svn_t;
float drawstring_svn(vector position, string text, vector scale, vector rgb, float alpha, float flag) = #321;

float textLengthUpToWidth_svn(string theText, float maxWidth, vector theSize, textLengthUpToWidth_widthFunction_svn_t w)
{
	float ICanHasKallerz;

	// detect color codes support in the width function
	ICanHasKallerz = (w("^7", theSize) == 0);

	// STOP.
	// The following function is SLOW.
	// For your safety and for the protection of those around you...
	// DO NOT CALL THIS AT HOME.
	// No really, don't.
	if(w(theText, theSize) <= maxWidth)
		return strlen(theText); // yeah!

	// binary search for right place to cut string
	float ch;
	float left, right, middle; // this always works
	left = 0;
	right = strlen(theText); // this always fails
	do
	{
		middle = floor((left + right) / 2);
		if(w(substring(theText, 0, middle), theSize) <= maxWidth)
			left = middle;
		else
			right = middle;
	}
	while(left < right - 1);

	if(ICanHasKallerz)
	{
		// NOTE: when color codes are involved, this binary search is,
		// mathematically, BROKEN. However, it is obviously guaranteed to
		// terminate, as the range still halves each time - but nevertheless, it is
		// guaranteed that it finds ONE valid cutoff place (where "left" is in
		// range, and "right" is outside).
		
		// terencehill: the following code detects truncated ^xrgb tags (e.g. ^x or ^x4)
		// and decrease left on the basis of the chars detected of the truncated tag
		// Even if the ^xrgb tag is not complete/correct, left is decreased
		// (sometimes too much but with a correct result)
		// it fixes also ^[0-9]
		while(left >= 1 && substring(theText, left-1, 1) == "^")
			left-=1;

		if (left >= 2 && substring(theText, left-2, 2) == "^x") // ^x/
			left-=2;
		else if (left >= 3 && substring(theText, left-3, 2) == "^x")
			{
				ch = str2chr(theText, left-1);
				if( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xr/
					left-=3;
			}
		else if (left >= 4 && substring(theText, left-4, 2) == "^x")
			{
				ch = str2chr(theText, left-2);
				if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') )
				{
					ch = str2chr(theText, left-1);
					if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xrg/
						left-=4;
				}
			}
	}
	
	return left;
}

string textShortenToWidth_svn(string theText, float maxWidth, vector theFontSize, textLengthUpToWidth_widthFunction_svn_t tw)
{
	if(tw(theText, theFontSize) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, textLengthUpToWidth_svn(theText, maxWidth - tw("...", theFontSize), theFontSize, tw)), "...");
}

float stringwidth_svn(string text, float handleColors, vector fontSize) = #327;
float stringwidth_colors_svn(string s, vector theSize)
{
	return stringwidth_svn(s, TRUE, theSize);
}

float stringwidth_nocolors_svn(string s, vector theSize)
{
	return stringwidth_svn(s, FALSE, theSize);
}

