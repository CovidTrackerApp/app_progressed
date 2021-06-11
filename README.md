# Current Catch#
First of all, run lib/widgets.dart.....and push the "Bypass" button.
Please replace the following:
                      await writeuuid("84887230-ca93-11eb-9234-677e39cede1e");
                      //String uu=await getuuid();
                      print("This is uuid 84887230-ca93-11eb-9234-677e39cede1e");
                      
with this, when any other of two is running it:
                      await writeuuid("12345670-ca93-11eb-9234-677e39cede1e");
                      //String uu=await getuuid();
                      print("This is uuid 12345670-ca93-11eb-9234-677e39cede1e");
                      
                      
So, that two guys have different id's to transmit....as we know that our static ID strategy is based on login/register, and server is not operational on it at the moment.
