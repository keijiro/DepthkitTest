using UnityEngine;
using UnityEditor;

namespace Ditho
{
    [CanEditMultipleObjects]
    [CustomEditor(typeof(Fiber))]
    sealed class FiberEditor : Editor
    {
        SerializedProperty _source;
        SerializedProperty _metadata;

        SerializedProperty _pointCount;
        SerializedProperty _curveLength;
        SerializedProperty _curveAnimation;

        SerializedProperty _noiseAmplitude;
        SerializedProperty _noiseAnimation;

        SerializedProperty _lineColor;
        SerializedProperty _attenuation;

        void OnEnable()
        {
            _source         = serializedObject.FindProperty("_source");
            _metadata       = serializedObject.FindProperty("_metadata");

            _pointCount     = serializedObject.FindProperty("_pointCount");
            _curveLength    = serializedObject.FindProperty("_curveLength");
            _curveAnimation = serializedObject.FindProperty("_curveAnimation");

            _noiseAmplitude = serializedObject.FindProperty("_noiseAmplitude");
            _noiseAnimation = serializedObject.FindProperty("_noiseAnimation");

            _lineColor      = serializedObject.FindProperty("_lineColor");
            _attenuation    = serializedObject.FindProperty("_attenuation");
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.PropertyField(_source);
            EditorGUILayout.PropertyField(_metadata);

            EditorGUILayout.Space();

            EditorGUI.BeginChangeCheck();
            EditorGUILayout.PropertyField(_pointCount);
            var needsReconstruct = EditorGUI.EndChangeCheck();

            EditorGUILayout.PropertyField(_curveLength);
            EditorGUILayout.PropertyField(_curveAnimation);

            EditorGUILayout.Space();

            EditorGUILayout.PropertyField(_noiseAmplitude);
            EditorGUILayout.PropertyField(_noiseAnimation);

            EditorGUILayout.Space();

            EditorGUILayout.PropertyField(_lineColor);
            EditorGUILayout.PropertyField(_attenuation);

            serializedObject.ApplyModifiedProperties();

            if (needsReconstruct)
                foreach (Fiber f in targets) f.ReconstructMesh();
        }
    }
}
