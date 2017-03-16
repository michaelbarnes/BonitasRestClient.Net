using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BonitasRestClient.Contracts
{
    public interface IAuthorisation
    {
        void Login();
        void Logout();
    }
}
