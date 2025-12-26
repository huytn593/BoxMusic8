using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace backend.Models
{
    public class Notifications
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string Id;

        [BsonRepresentation(BsonType.ObjectId)]
        [BsonRequired]
        public string ReceiverId { get; set; }

        [BsonRequired]
        public string Title { get; set; }

        [BsonRequired]
        public string Content { get; set; }

        [BsonRequired]
        public bool IsViewed { get; set; }

        [BsonRequired]
        public DateTime CreateAt { get; set; }
    }
}
