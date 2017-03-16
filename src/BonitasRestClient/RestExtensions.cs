using RestSharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Blazingchilli.Common.Bpm
{
    public static class RestExtensions
    {
        public static string ValidateBaseUrl(this string url)
        {
            if (url.Last() != '/')
                url = url + "/";

            return url;
        }

        public static RestRequest AddCookies(this RestRequest request, IList<RestResponseCookie> cookies)
        {
            foreach (var cookie in cookies)
            {
                request.AddCookie(cookie.Name, cookie.Value);
            }

            return request;
        }

        public static IRestResponse Execute(this RestRequest request, RestClient client)
        {
            return client.Execute(request);
        }
    }
}
