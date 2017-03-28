using System;
using System.Collections.Generic;
using System.Collections;
using System.Linq;

namespace ConfluencePS
{

	public class Icon {
		public String Path { get; set; }
		public Int32 Width { get; set; }
		public Int32 Height { get; set; }
		public Boolean IsDefault { get; set; }
	}

	public class Author {
		public String UserName { get; set; }
		public String DisplayName { get; set; }
		public String Key { get; set; }
		public Icon Picture { get; set; }
	}

	public class Version {
		public Author By { get; set; }
		public DateTime Author { get; set; }
		public Int32 Number { get; set; }
		public String Message { get; set; }
		public Boolean MinorEdit { get; set; }
	}

	public class Space {
		private String _description;

		public Int32 Id { get; set; }
		public String Key { get; set; }
		public String Name { get; set; }
		public Icon Icon { get; set; }
		public String Type { get; set; }
		// TODO: homepage ?
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

	public class Page {
		private String _description;

		public Int32 ID { get; set; }
		public String Status { get; set; }
		public String Title { get; set; }
		public Space Space { get; set; }
		public Version Version { get; set; }
		public dynamic Body {
			set {
				try {
					dynamic intermediateValue = value.storage;
					_description = intermediateValue.value.ToString();
					return;
				} catch {
					var dict = value as IDictionary;
					if(dict != null && dict.Contains("storage")) {
						_description = ((Hashtable)dict["storage"])["value"].ToString();
					} else {
						_description = value.ToString();
					}
				}
			}
			get {
				return _description;
			}
		}
		public Page[] Ancestors { get; set; }
		// TODO: URL?
	}
}
