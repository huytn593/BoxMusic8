using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace backend.Interfaces
{
    public interface IJWTService
    {
        string GenerateJwtToken(string userId, string fullname, string role);
    }
}
