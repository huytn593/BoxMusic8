using backend.Controllers;
using System.Collections.Generic;

namespace backend.DTOs
{
    public class SearchResultDto
    {
        public List<TrackSearchDto> Tracks { get; set; }
        public List<SearchUserDto> Users { get; set; }
    }
} 