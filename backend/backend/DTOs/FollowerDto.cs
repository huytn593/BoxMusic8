namespace backend.DTOs
{
    public class FollowCheckResponse
    {
        public bool Following { get; set; }
    }

    public class FollowingListResponse
    {
        public string FollowerId { get; set; }
        public List<string> FollowingList { get; set; }
        public int Count { get; set; }
    }

    public class FollowingDetailsListResponse
    {
        public string FollowerId { get; set; }
        public List<FollowingDetailsResponse> FollowingList { get; set; }
        public int Count { get; set; }
    }

    public class FollowingDetailsResponse
    {
        public string FollowingId { get; set; }
        public string FollowingName { get; set; }
        public string FollowingEmail { get; set; }
        public string FollowingAvatar { get; set; }
        public string FollowingRole { get; set; }
        public int FollowingGender { get; set; }
        public DateTime FollowingDateOfBirth { get; set; }
        public bool IsFollowing { get; set; }
    }
}
