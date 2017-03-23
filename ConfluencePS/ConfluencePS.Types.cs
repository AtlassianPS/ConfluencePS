using System;
using System.Collections;
using System.Linq;

namespace ConfluencePS
{

	public class CIcon {
		public String Path { get; set; }
		public Int32 Width { get; set; }
		public Int32 Height { get; set; }
		public Boolean IsDefault { get; set; }
	}

	public class Space {
		private String _description;

		public Int32 Id { get; set; }
		public String Key { get; set; }
		public String Name { get; set; }
		public CIcon Icon { get; set; }
		public String Type { get; set; }
		public dynamic Description {
			set {
				try {
					dynamic intermediateValue = value.plain;
					_description = intermediateValue.value.ToString();
					return;
				} catch {
					var dict = value as IDictionary;
					if(dict != null && dict.Contains("plain")) {
						_description = ((Hashtable)dict["plain"])["value"].ToString();
					} else {
						_description = value.ToString();
					}
				}
			}
			get {
				return _description;
			}
		}
	}
}
