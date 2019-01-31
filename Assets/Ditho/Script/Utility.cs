using UnityEngine;

namespace Ditho
{
    static class Utility
    {
        public static void Destroy(Object o)
        {
            if (o == null) return;
            if (Application.isPlaying)
                Object.Destroy(o);
            else
                Object.DestroyImmediate(o);
        }

        public static Depthkit.Depthkit_Metadata LoadMetadata(string name)
        {
            var path = System.IO.Path.Combine(
                Application.streamingAssetsPath,
                name + ".txt"
            );
            var json = System.IO.File.ReadAllText(path);
            return Depthkit.Depthkit_Metadata.CreateFromJSON(json);
        }

        public static void ApplyMetadata(Depthkit.Depthkit_Metadata metadata, Material material)
        {
            var pers = metadata.perspectives[0];
            material.SetVector("_Crop", pers.crop);
            material.SetVector("_ImageDimensions", pers.depthImageSize);
            material.SetVector("_FocalLength", pers.depthFocalLength);
            material.SetVector("_PrincipalPoint", pers.depthPrincipalPoint);
            material.SetFloat("_NearClip", pers.nearClip);
            material.SetFloat("_FarClip", pers.farClip);
            material.SetMatrix("_Extrinsics", pers.extrinsics);
        }
    }
}
