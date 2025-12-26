using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace backend.Models
{
    public class Followers
    {
        [BsonId]
        [BsonRepresentation(BsonType.String)]
        [BsonRequired]
        public string Id { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string FollowerId { get; set; }

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string FollowingId { get; set; }
    }
}
