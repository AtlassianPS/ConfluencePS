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

	public class User {
		public String UserName { get; set; }
		public String DisplayName { get; set; }
		public String UserKey { get; set; }
		public Icon ProfilePicture { get; set; }
	}

	public class Version {
		public User By { get; set; }
		public DateTime When { get; set; }
		public String FriendlyWhen { get; set; }
		public Int32 Number { get; set; }
		public String Message { get; set; }
		public Boolean MinorEdit { get; set; }
	}

	public class Space {
		public Int32 Id { get; set; }
		public String Key { get; set; }
		public String Name { get; set; }
		public Icon Icon { get; set; }
		public String Type { get; set; }
		public String Description { get; set; }
		public Page Homepage { get; set; }
	}

	public class Page {
		public Int32 ID { get; set; }
		public String Status { get; set; }
		public String Title { get; set; }
		public Space Space { get; set; }
		public Version Version { get; set; }
		public String Body { get; set; }
		public Page[] Ancestors { get; set; }
		public String URL { get; set; }
		public String ShortURL { get; set; }
	}

	public class Label {
		public Int32 ID { get; set; }
		public String Prefix { get; set; }
		public String Name { get; set; }
	}
}
